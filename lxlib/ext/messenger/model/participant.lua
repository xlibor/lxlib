
local lx, _M = oo{
    _cls_ = '',
    _ext_ = 'model',
    _mix_ = 'softDelete'
}

local app, lf, tb, str = lx.kit()
local Models = lx.use('models')

function _M:ctor(attrs)

    self.table = Models.table('messenger.participant')
    self.fillable = {'thread_id', 'user_id', 'last_read'}
    self.dates = {'deleted_at', 'last_read'}
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

return _M

