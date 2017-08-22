
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

local abort = lx.h.abort
local router

function _M._init_()

    if not router then
        if not app:isCmdMode() then
            router = app.router
        end
    end
end

function _M:new()

    local this = {
    }
    
    return oo(this, mt)
end

-- Checks if the current user has a role by its name
-- @param string name Role name.
-- @return bool

function _M:hasRole(role, requireAll)

    requireAll = requireAll or false
    local user = self:user()
    if user then
        
        return user:hasRole(role, requireAll)
    end
    
    return false
end

-- Check if the current user has a permission by its name
-- @param string permission Permission string.
-- @return bool

function _M:can(permission, requireAll)

    requireAll = requireAll or false
    local user = self:user()
    if user then
        
        return user:can(permission, requireAll)
    end
    
    return false
end

-- Check if the current user has a role or permission by its name
-- @param table|string roles            The role(s) needed.
-- @param table|string permissions      The permission(s) needed.
-- @param table options                 The Options.
-- @return bool

function _M:ability(roles, permissions, options)

    options = options or {}
    local user = self:user()
    if user then
        
        return user:ability(roles, permissions, options)
    end
    
    return false
end

-- Get the currently authenticated user or null.

function _M:user()

    return app.auth:user()
end

-- Filters a route for a role or set of roles.
-- If the third parameter is null then abort with status code 403.
-- Otherwise the result is returned.
-- @param string       route      Route pattern. i.e: "admin/*"
-- @param table|string roles      The role(s) needed
-- @param mixed        result     i.e: Redirect::to('/')
-- @param bool         requireAll User must have all roles
-- @return mixed

function _M:routeNeedsRole(route, roles, result, requireAll)

    requireAll = lf.needTrue(requireAll)
    local filterName = lf.isTbl(roles) and str.join(roles, '_') or roles
    filterName = filterName .. '_' .. str.substr(md5(route), 1, 6)
    local closure = function()
        hasRole = self:hasRole(roles, requireAll)
        if not hasRole then
            
            return lf.isEmpty(result) and abort(403) or result
        end
    end
    -- Same as Route::filter, registers a new filter
    router:filter(filterName, closure)
    -- Same as Route::when, assigns a route pattern to the
    -- previously created filter.
    router:when(route, filterName)
end

-- Filters a route for a permission or set of permissions.
-- If the third parameter is null then abort with status code 403.
-- Otherwise the result is returned.
-- @param string       route       Route pattern. i.e: "admin/*"
-- @param table|string permissions The permission(s) needed
-- @param mixed        result      i.e: Redirect::to('/')
-- @param bool         requireAll  User must have all permissions
-- @return mixed

function _M:routeNeedsPermission(route, permissions, result, requireAll)

    requireAll = lf.needTrue(requireAll)
    local filterName = lf.isTbl(permissions) and str.join(permissions, '_') or permissions
    filterName = filterName .. '_' .. str.substr(md5(route), 1, 6)
    local closure = function()
        hasPerm = self:can(permissions, requireAll)
        if not hasPerm then
            
            return lf.isEmpty(result) and abort(403) or result
        end
    end
    -- Same as Route::filter, registers a new filter
    router:filter(filterName, closure)
    -- Same as Route::when, assigns a route pattern to the
    -- previously created filter.
    router:when(route, filterName)
end

-- Filters a route for role(s) and/or permission(s).
-- If the third parameter is null then abort with status code 403.
-- Otherwise the result is returned.
-- @param string       route       Route pattern. i.e: "admin/*"
-- @param table|string roles       The role(s) needed
-- @param table|string permissions The permission(s) needed
-- @param mixed        result      i.e: Redirect::to('/')
-- @param bool         requireAll  User must have all roles and permissions

function _M:routeNeedsRoleOrPermission(route, roles, permissions, result, requireAll)

    requireAll = requireAll or false
    local filterName = lf.isTbl(roles) and str.join(roles, '_') or roles
    filterName = filterName .. '_' .. (lf.isTbl(permissions) and str.join(permissions, '_') or permissions)
    filterName = filterName .. '_' .. str.substr(md5(route), 1, 6)
    local closure = function()
        hasRole = self:hasRole(roles, requireAll)
        hasPerms = self:can(permissions, requireAll)
        if requireAll then
            hasRolePerm = hasRole and hasPerms
        else 
            hasRolePerm = hasRole or hasPerms
        end
        if not hasRolePerm then
            
            return lf.isEmpty(result) and abort(403) or result
        end
    end
    -- Same as Route::filter, registers a new filter
    router:filter(filterName, closure)
    -- Same as Route::when, assigns a route pattern to the
    -- previously created filter.
    router:when(route, filterName)
end

return _M

