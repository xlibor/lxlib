
local __ = {
    _cls_ = ''
}
-- Many-to-Many relations with the user model.
-- @return belongsToMany

function __:users() end

-- Many-to-Many relations with the permission model.
-- Named "perms" for backwards compatibility. Also because "perms" is short and sweet.
-- @return belongsToMany

function __:perms() end

-- Save the inputted permissions.
-- @param mixed inputPermissions

function __:savePermissions(inputPermissions) end

-- Attach permission to current role.
-- @param object|array permission

function __:attachPermission(permission) end

-- Detach permission form current role.
-- @param object|array permission

function __:detachPermission(permission) end

-- Attach multiple permissions to current role.
-- @param mixed permissions

function __:attachPermissions(permissions) end

-- Detach multiple permissions from current role
-- @param mixed permissions

function __:detachPermissions(permissions) end

return __

