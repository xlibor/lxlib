
local lx, _M = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

local cache = app.cache

--Big block of caching functionality.

function _M:cachedPermissions()

    local rolePrimaryKey = self.primaryKey
    local cacheKey = 'entrust_permissions_for_role_' .. self[rolePrimaryKey]
    
    return cache:tags(app:conf('entrust.permission_role_table')):remember(cacheKey, app:conf('cache.ttl'), function()
        
        return self:perms():get()
    end)
end

function _M:save(options)

    options = options or {}
    --both inserts and updates
    if not self:__super('save', options) then
        
        return false
    end
    cache:tags(app:conf('entrust.permission_role_table')):flush()
    
    return true
end

function _M:delete(options)

    options = options or {}
    --soft or hard
    if not self:__super('delete', options) then
        
        return false
    end
    cache:tags(app:conf('entrust.permission_role_table')):flush()
    
    return true
end

function _M:restore()

    --soft delete undo's
    if not self:__super('restore') then
        
        return false
    end
    cache:tags(app:conf('entrust.permission_role_table')):flush()
    
    return true
end

-- Many-to-Many relations with the user model.
-- @return belongsToMany

function _M:users()

    return self:belongsToMany(
        app:conf('auth.providers.users.model'),
        app:conf('entrust.role_user_table'),
        app:conf('entrust.role_foreign_key'),
        app:conf('entrust.user_foreign_key')
    )
end

-- Many-to-Many relations with the permission model.
-- Named "perms" for backwards compatibility. Also because "perms" is short and sweet.
-- @return belongsToMany

function _M:perms()

    return self:belongsToMany(
        app:conf('entrust.permission'),
        app:conf('entrust.permission_role_table'),
        app:conf('entrust.role_foreign_key'),
        app:conf('entrust.permission_foreign_key')
    )
end

-- Boot the role model
-- Attach event listener to remove the many-to-many records when trying to delete
-- Will NOT delete any records if the role model uses soft deletes.
-- @return bool

function _M:boot()

    self:__super(_M, 'boot')
    -- static.deleting(function(role)
    --     if not app:conf('entrust.role'):__has('bootSoftDeletes') then
    --         role:users():sync({})
    --         role:perms():sync({})
    --     end
    --     return true
    -- end)
end

-- Checks if the role has a permission by its name.
-- @param string|array name       Permission name or table of permission names.
-- @param bool         requireAll All permissions in the table are required.
-- @return bool

function _M:hasPermission(name, requireAll)

    requireAll = requireAll or false
    local hasPermission
    if lf.isTbl(name) then
        for _, permissionName in ipairs(name) do
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
        for _, permission in ipairs(self:cachedPermissions()) do
            if permission.name == name then
                return true
            end
        end
    end
    
    return false
end

-- Save the inputted permissions.
-- @param mixed inputPermissions

function _M:savePermissions(inputPermissions)

    if not lf.isEmpty(inputPermissions) then
        self:perms():sync(inputPermissions)
    else 
        self:perms():detach()
    end
end

-- Attach permission to current role.
-- @param object|array permission

function _M:attachPermission(permission)

    if lf.isObj(permission) then
        permission = permission:getKey()
    end
    if lf.isTbl(permission) then
        permission = permission.id
    end
    self:perms():attach(permission)
end

-- Detach permission from current role.
-- @param object|array permission

function _M:detachPermission(permission)

    if lf.isObj(permission) then
        permission = permission:getKey()
    end
    if lf.isTbl(permission) then
        permission = permission.id
    end
    self:perms():detach(permission)
end

-- Attach multiple permissions to current role.
-- @param mixed permissions

function _M:attachPermissions(permissions)

    for _, permission in ipairs(permissions) do
        self:attachPermission(permission)
    end
end

-- Detach multiple permissions from current role
-- @param mixed permissions

function _M:detachPermissions(permissions)

    for _, permission in ipairs(permissions) do
        self:detachPermission(permission)
    end
end

return _M

