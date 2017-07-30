-- This file is part of Entrust,
-- a role & permission management solution for Laravel.
-- @license MIT
-- @package Zizaco\Entrust


local lx, _M = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

-- Many-to-Many relations with role model.
-- @return \Illuminate\Database\Eloquent\Relations\BelongsToMany

function _M:roles()

    return self:belongsToMany(Config.get('entrust.role'), Config.get('entrust.permission_role_table'))
end

-- Boot the permission model
-- Attach event listener to remove the many-to-many records when trying to delete
-- Will NOT delete any records if the permission model uses soft deletes.
-- @return void|bool

function _M.s__.boot()

    parent.boot()
    static.deleting(function(permission)
        if not Config.get('entrust.permission'):__has('bootSoftDeletes') then
            permission:roles():sync({})
        end
        
        return true
    end)
end

return _M

