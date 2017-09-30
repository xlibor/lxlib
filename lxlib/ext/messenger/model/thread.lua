
local lx, _M = oo{
    _cls_ = '',
    _ext_ = 'model',
    _mix_ = 'softDelete'
}

local app, lf, tb, str, new = lx.kit()
local try = lx.try
local Models = lx.use('models')
local Messenger

function _M:ctor()

    if not Messenger then
        Messenger = Models.init('messenger')
    end
    
    self.table = Messenger.table('thread')
    self.fillable = {'subject'}
    self.dates = {'deleted_at'}
end

-- Messages relationship.
-- @return hasMany

function _M:messages()

    return self:hasMany(Messenger.model('message'), 'thread_id', 'id')
end

-- Returns the latest message from a thread.
-- @return messenger.model.message

function _M:getLatestMessageAttr()

    return self:messages():latest():first()
end

-- Participants relationship.
-- @return hasMany

function _M:participants()

    return self:hasMany(Messenger.model('participant'), 'thread_id', 'id')
end

-- User's relationship.
-- @return belongsToMany

function _M:users()

    return self:belongsToMany(Messenger.model('user'), Messenger.table('participant'), 'thread_id', 'user_id')
end

-- Returns the user object that created the thread.
-- @return mixed

function _M:creator()

    local firstMessage = self:messages():withTrashed():oldest():first()
    
    return firstMessage and firstMessage.user
end

-- Returns all of the latest threads by updated_at date.
-- @return mixed

function _M:getAllLatest()

    return self:latest('updated_at')
end

-- Returns all threads by subject.
-- @return mixed

function _M:getBySubject(subjectQuery)

    return self:where('subject', 'like', subjectQuery):get()
end

-- Returns an table of user ids that are associated with the thread.
-- @param null userId
-- @return table

function _M:participantsUserIds(userId)

    local users = self:participants():withTrashed():select('user_id'):get():map(function(participant)
        
        return participant.user_id
    end)
    if userId then
        users:push(userId)
    end
    
    return users:toArray()
end

-- Returns threads that the user is associated with.
-- @param orm.query     query
-- @param mixed         userId
-- @return mixed

function _M:scopeForUser(query, userId)

    local participantsTable = Messenger.table('participant')
    local threadsTable = Messenger.table('thread')
    
    return query:join(
        participantsTable, self:getQualifiedKeyName(), '=', participantsTable .. '.thread_id'):where(participantsTable .. '.user_id', userId):where(participantsTable .. '.deleted_at', nil):select(threadsTable .. '.*')
end

-- Returns threads with new messages that the user is associated with.
-- @param orm.query     query
-- @param mixed         userId
-- @return mixed

function _M:scopeForUserWithNewMessages(query, userId)

    local participantTable = Messenger.table('participant')
    local threadsTable = Messenger.table('thread')
    
    return query:join(participantTable, self:getQualifiedKeyName(), '=', participantTable .. '.thread_id'):where(participantTable .. '.user_id', userId):whereNull(participantTable .. '.deleted_at'):where(function(query)
        query:where(threadsTable .. '.updated_at', '>', self:getConnection():raw(self:getConnection():getTablePrefix() .. participantTable .. '.last_read')):orWhereNull(participantTable .. '.last_read')
    end):select(threadsTable .. '.*')
end

-- Returns threads between given user ids.
-- @param orm.query     query
-- @param model         participants
-- @return mixed

function _M:scopeBetween(query, participants)

    return query:whereHas('participants', function(q)
        q:whereIn('user_id', participants)
        :select({'thread_id', _, 'distinct'})
        :groupBy('thread_id')
        :havingRaw('COUNT(thread_id)=' .. #participants)
    end)
end

-- Add users to thread as participants.
-- @param table|mixed userId

function _M:addParticipant(userId)

    local userIds = lf.needList(userId)
    for _, userId in ipairs(userIds) do
        Messenger.participant():firstOrCreate({user_id = userId, thread_id = self.id})
    end
end

-- Remove participants from thread.
-- @param table|mixed userId

function _M:removeParticipant(userId)

    local userIds = lf.isTbl(userId) and userId or lf.needList(func_get_args())
    Messenger.participant():where('thread_id', self.id):whereIn('user_id', userIds):delete()
end

-- Mark a thread as read for a user.
-- @param mixed userId

function _M:markAsRead(userId)

    try(function()
        participant = self:getParticipantFromUser(userId)
        participant.last_read = lf.datetime()
        participant:save()
    end)
    :catch('modelNotFoundException', function(e) 
    end)
    :run()
end

-- See if the current thread is unread by the user.
-- @param mixed userId
-- @return bool

function _M:isUnread(userId)

    local ok, ret = try(function()
        participant = self:getParticipantFromUser(userId)
        if participant.last_read == nil or self.updated_at:gt(participant.last_read) then
            
            return true
        end
    end)
    :catch('modelNotFoundException', function(e) 
    end)
    :run()
    
    if ok and ret then
        return ret
    end

    return false
end

-- Finds the participant record from a user id.
-- @param mixed userId
-- @return mixed

function _M:getParticipantFromUser(userId)

    return self:participants():where('user_id', userId):firstOrFail()
end

-- Restores all participants within a thread that has a new message.

function _M:activateAllParticipants()

    local participants = self:participants():withTrashed():get()
    for _, participant in pairs(participants) do
        participant:restore()
    end
end

-- Generates a string of participant information.
-- @param null      userId
-- @param table     columns
-- @return string

function _M:participantsString(userId, columns)

    columns = columns or {'name'}
    local participantsTable = Messenger.table('participant')
    local usersTable = Messenger.table('user')
    local userPrimaryKey = app.auth:user():getKeyName()
    local selectString = self:createSelectString(columns)
    local participantNames = self:getConnection():table(usersTable):join(participantsTable, usersTable .. '.' .. userPrimaryKey, '=', participantsTable .. '.user_id'):where(participantsTable .. '.thread_id', self.id):select(self:getConnection():raw(selectString))
    if userId ~= nil then
        participantNames:where(usersTable .. '.' .. userPrimaryKey, '!=', userId)
    end
    
    return participantNames:implode('name', ', ')
end

-- Checks to see if a user is a current participant of the thread.
-- @param mixed userId
-- @return bool

function _M:hasParticipant(userId)

    local participants = self:participants():where('user_id', '=', userId)
    if participants:count() > 0 then
        
        return true
    end
    
    return false
end

-- Generates a select string used in participantsString().
-- @param table columns
-- @return string

function _M.__:createSelectString(columns)

    local dbDriver = self:getConnection():getDriverName()
    local tablePrefix = self:getConnection():getTablePrefix()
    local usersTable = Messenger.table('user')
    local st = dbDriver
    if st == 'pgsql' then
    elseif st == 'sqlite' then
        columnString = str.join(" || ' ' || " .. tablePrefix .. usersTable .. '.', columns)
        selectString = '(' .. tablePrefix .. usersTable .. '.' .. columnString .. ') as name'
    elseif st == 'sqlsrv' then
        columnString = str.join(" + ' ' + " .. tablePrefix .. usersTable .. '.', columns)
        selectString = '(' .. tablePrefix .. usersTable .. '.' .. columnString .. ') as name'
    else 
        columnString = str.join(", ' ', " .. tablePrefix .. usersTable .. '.', columns)
        selectString = 'concat(' .. tablePrefix .. usersTable .. '.' .. columnString .. ') as name'
    end
    
    return selectString
end

-- Returns table of unread messages in thread for given user.
-- @param mixed userId
-- @return col

function _M:userUnreadMessages(userId)

    local messages = self:messages():get()

    local ok, ret = try(function()
        participant = self:getParticipantFromUser(userId)
    end)
    :catch('modelNotFoundException', function(e) 
        
        return {}
    end)
    :run()

    if ok and ret then
        return ret
    end
    if not participant.last_read then
        
        return messages
    end
    
    return tb.filter(messages, function(message)
        
        return message.updated_at > participant.last_read
    end)
end

-- Returns count of unread messages in thread for given user.
-- @param mixed userId
-- @return int

function _M:userUnreadMessagesCount(userId)

    return #self:userUnreadMessages(userId)
end

return _M

