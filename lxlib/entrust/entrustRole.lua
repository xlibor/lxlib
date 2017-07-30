
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'model',
    _bond_ = 'entrustRoleBond',
    _mix_ = 'entrustRoleMix'
}

local app, lf, tb, str = lx.kit()

function _M:ctor(attrs)

    attributes = attributes or {}
    parent.__construct(attributes)
    self.table = Config.get('entrust.roles_table')
end

return _M

