
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'model',
    _bond_ = 'entrustPermissionInterface',
    _mix_ = 'entrustPermissionTrait'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        table = nil
    }
    
    return oo(this, mt)
end

-- The database table used by the model.
-- @var string
-- Creates a new instance of the model.
-- @param table attributes

function _M:ctor(attributes)

    attributes = attributes or {}
    parent.__construct(attributes)
    self.table = Config.get('entrust.permissions_table')
end

return _M

