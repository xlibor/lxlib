-- This file is part of Entrust,
-- a role & permission management solution for Laravel.
-- @license MIT
-- @package Zizaco\Entrust

local lx, _M = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

--Big block of caching functionality.
function _M:cachedPermissions()

    local rolePrimaryKey = self.primaryKey
    local cacheKey = 'entrust_permissions_for_role_' .. self[rolePrimaryKey]
    
    return Cache.tags(Config.get('entrust.permission_role_table')):remember(cacheKey, Config.get('cache.ttl'), function()
        
        return self:perms():get()
    end)
end

function _M:save(options)

    options = options or {}
    --both inserts and updates
    if not parent.save(options) then
        
        return false
    end
    Cache.tags(Config.get('entrust.permission_role_table')):flush()
    
    return true
end

function _M:delete(options)

    options = options or {}
    --soft or hard
    if not parent.delete(options) then
        
        return false
    end
    Cache.tags(Config.get('entrust.permission_role_table')):flush()
    
    return true
end

function _M:restore()

    --soft delete undo's
    if not parent.restore() then
        
        return false
    end
    Cache.tags(Config.get('entrust.permission_role_table')):flush()
    
    return true
end

-- Many-to-Many relations with the user model.
-- @return \Illuminate\Database\Eloquent\Relations\BelongsToMany

function _M:users()

    return self:belongsToMany(Config.get('auth.providers.users.model'), Config.get('entrust.role_user_table'), Config.get('entrust.role_foreign_key'), Config.get('entrust.user_foreign_key'))
    -- return this->belongsToMany(Config::get('auth.model'), Config::get('entrust.role_user_table'));
end

-- Many-to-Many relations with the permission model.
-- Named "perms" for backwards compatibility. Also because "perms" is short and sweet.
-- @return \Illuminate\Database\Eloquent\Relations\BelongsToMany

function _M:perms()

    return self:belongsToMany(Config.get('entrust.permission'), Config.get('entrust.permission_role_table'), Config.get('entrust.role_foreign_key'), Config.get('entrust.permission_foreign_key'))
end

-- Boot the role model
-- Attach event listener to remove the many-to-many records when trying to delete
-- Will NOT delete any records if the role model uses soft deletes.
-- @return void|bool

function _M.s__.boot()

    parent.boot()
    static.deleting(function(role)
        if not Config.get('entrust.role'):__has('bootSoftDeletes') then
            role:users():sync({})
            role:perms():sync({})
        end
        
        return true
    end)
end

-- Checks if the role has a permission by its name.
-- @param string|array name       Permission name or table of permission names.
-- @param bool         requireAll All permissions in the table are required.
-- @return bool

function _M:hasPermission(name, requireAll)

    requireAll = requireAll or false
    local hasPermission
    if lf.isTbl(name) then
        for _, permissionName in pairs(name) do
            hasPermission = self:hasPermission(permissionName)
            if hasPermission and not requireAll then
                
                return true
            elseif not hasPermission and requireAll then
                
                return false
            end
        end
        -- If we've made it this far and requireAll is FALSE, then NONE of the permissions were found
        -- If we've made it this far and requireAll is TRUE, then ALL of the permissions were found.
        -- Return the value of requireAll;
        
        return requireAll
    else 
        for _, permission in pairs(self:cachedPermissions()) do
            if permission.name == name then
                
                return true
            end
        end
    end
    
    return false
end

-- Save the inputted permissions.
-- @param mixed inputPermissions
-- @return void

function _M:savePermissions(inputPermissions)

    if not lf.isEmpty(inputPermissions) then
        self:perms():sync(inputPermissions)
    else 
        self:perms():detach()
    end
end

-- Attach permission to current role.
-- @param object|array permission
-- @return void

function _M:attachPermission(permission)

    if lf.isObj(permission) then
        permission = permission:getKey()
    end
    if lf.isTbl(permission) then
        permission = permission['id']
    end
    self:perms():attach(permission)
end

-- Detach permission from current role.
-- @param object|array permission
-- @return void

function _M:detachPermission(permission)

    if lf.isObj(permission) then
        permission = permission:getKey()
    end
    if lf.isTbl(permission) then
        permission = permission['id']
    end
    self:perms():detach(permission)
end

-- Attach multiple permissions to current role.
-- @param mixed permissions
-- @return void

function _M:attachPermissions(permissions)

    for _, permission in pairs(permissions) do
        self:attachPermission(permission)
    end
end

-- Detach multiple permissions from current role
-- @param mixed permissions
-- @return void

function _M:detachPermissions(permissions)

    for _, permission in pairs(permissions) do
        self:detachPermission(permission)
    end
end

return _M

