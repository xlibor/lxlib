
local lx, _M = oo{
    _cls_ = '',
    _ext_ = 'model',
    _mix_ = 'softDelete'
}

local app, lf, tb, str = lx.kit()
local Models = lx.use('models')

function _M:ctor(attrs)

    self.table = Models.table('messenger.message')
    self.touches = {'thread'}
    self.fillable = {'thread_id', 'user_id', 'body'}
    self.dates = {'deleted_at'}
end

-- Thread relationship.
-- @return belongsTo

function _M:thread()

    return self:belongsTo(Models.model('messenger.thread'), 'thread_id', 'id')
end

-- User relationship.
-- @return belongsTo

function _M:user()

    return self:belongsTo(Models.model('user'), 'user_id')
end

-- Participants relationship.
-- @return hasMany

function _M:participants()

    return self:hasMany(Models.model('messenger.participant'), 'thread_id', 'thread_id')
end

-- Recipients of this message.
-- @return hasMany

function _M:recipients()

    return self:participants():where('user_id', '!=', self.user_id)
end

-- Returns unread messages given the userId.
-- @param orm.query     query
-- @param int           userId
-- @return mixed

function _M:scopeUnreadForUser(query, userId)

    return query:has('thread'):where('user_id', '!=', userId):whereHas('participants', function(query)
        query:where('user_id', userId):where(function(q)
            q:where('last_read', '<', DB.raw(self:getTable() .. '.created_at')):orWhereNull('last_read')
        end)
    end)
end

return _M

