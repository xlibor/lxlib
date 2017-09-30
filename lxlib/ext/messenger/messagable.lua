
local lx, _M = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()
local Models = lx.use('models')

-- Message relationship.
-- @return hasMany

function _M:messages()

    return self:hasMany(Models.model('messenger.message'))
end

-- Participants relationship.
-- @return hasMany

function _M:participants()

    return self:hasMany(Models.model('messenger.participant'))
end

-- Thread relationship.
-- @return belongsToMany

function _M:threads()

    return self:belongsToMany(Models.model('messenger.thread'), Models.table('messenger.participant'), 'user_id', 'thread_id')
end

-- Returns the new messages count for user.
-- @return int

function _M:newThreadsCount()

    return self:threadsWithNewMessages():count()
end

-- Returns the new messages count for user.
-- @return int

function _M:unreadMessagesCount()

    return Message.unreadForUser(self:getKey()):count()
end

-- Returns all threads with new messages.
-- @return belongsToMany

function _M:threadsWithNewMessages()

    local participantTable = Models.table('participants')
    local threadTable = Models.table('threads')

    return self:threads()
        :whereNull(participantTable .. '.last_read')
        :orWhere(threadTable .. '.updated_at', '>',
            participantTable .. '.last_read'
        )
        :get()
end

return _M

