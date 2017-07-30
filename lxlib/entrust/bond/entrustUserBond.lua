-- This file is part of Entrust,
-- a role & permission management solution for Laravel.
-- @license MIT
-- @package Zizaco\Entrust
local __ = {
    _cls_ = ''
}
-- Many-to-Many relations with Role.
-- @return \Illuminate\Database\Eloquent\Relations\BelongsToMany

function __:roles() end

-- Checks if the user has a role by its name.
-- @param string|array name       Role name or table of role names.
-- @param bool         requireAll All roles in the table are required.
-- @return bool

function __:hasRole(name, requireAll) end

-- Check if user has a permission by its name.
-- @param string|array permission Permission string or table of permissions.
-- @param bool         requireAll All permissions in the table are required.
-- @return bool

function __:can(permission, requireAll) end

-- Checks role(s) and permission(s).
-- @param string|array roles       Array of roles or comma separated string
-- @param string|array permissions Array of permissions or comma separated string.
-- @param table        options     validate_all (true|false) or return_type (boolean|array|both)
-- @throws \InvalidArgumentException
-- @return table|bool

function __:ability(roles, permissions, options) end

-- Alias to eloquent many-to-many relation's attach() method.
-- @param mixed role

function __:attachRole(role) end

-- Alias to eloquent many-to-many relation's detach() method.
-- @param mixed role

function __:detachRole(role) end

-- Attach multiple roles to a user
-- @param mixed roles

function __:attachRoles(roles) end

-- Detach multiple roles from a user
-- @param mixed roles

function __:detachRoles(roles) end

return __

