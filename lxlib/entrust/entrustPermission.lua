
local lx, _M, mt = oo{
    _cls_   = '',
    _ext_   = 'model',
    _bond_  = 'entrustPermissionBond'
}

local app, lf, tb, str = lx.kit()

-- The database table used by the model.
-- @var string
-- Creates a new instance of the model.
-- @param table attributes

function _M:ctor(attrs)

    self.table = app:conf('entrust.permissions_table')
end

-- Boot the permission model
-- Attach event listener to remove the many-to-many records when trying to delete
-- Will NOT delete any records if the permission model uses soft deletes.
-- @return void|bool

function _M:boot()

    self:__super('boot')
    -- static.deleting(function(permission)
    --     if not app:conf('entrust.permission'):__has('bootSoftDeletes') then
    --         permission:roles():sync({})
    --     end
        
    --     return true
    -- end)
end

function _M:roles()

    return self:belongsToMany(app:conf('entrust.role'), app:conf('entrust.permission_role_table'))
end

return _M

