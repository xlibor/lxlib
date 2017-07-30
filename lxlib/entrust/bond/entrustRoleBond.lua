-- This file is part of Entrust,
-- a role & permission management solution for Laravel.
-- @license MIT
-- @package Zizaco\Entrust
local __ = {
    _cls_ = ''
}
-- Many-to-Many relations with the user model.
-- @return \Illuminate\Database\Eloquent\Relations\BelongsToMany

function __:users() end

-- Many-to-Many relations with the permission model.
-- Named "perms" for backwards compatibility. Also because "perms" is short and sweet.
-- @return \Illuminate\Database\Eloquent\Relations\BelongsToMany

function __:perms() end

-- Save the inputted permissions.
-- @param mixed inputPermissions
-- @return void

function __:savePermissions(inputPermissions) end

-- Attach permission to current role.
-- @param object|array permission
-- @return void

function __:attachPermission(permission) end

-- Detach permission form current role.
-- @param object|array permission
-- @return void

function __:detachPermission(permission) end

-- Attach multiple permissions to current role.
-- @param mixed permissions
-- @return void

function __:attachPermissions(permissions) end

-- Detach multiple permissions from current role
-- @param mixed permissions
-- @return void

function __:detachPermissions(permissions) end

return __

