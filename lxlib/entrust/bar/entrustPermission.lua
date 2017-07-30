-- This file is part of Entrust,
-- a role & permission management solution for Laravel.
-- @license MIT
-- @package Zizaco\Entrust


local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        auth = nil
    }
    
    return oo(this, mt)
end

-- Creates a new instance of the middleware.
-- @param Guard auth

function _M:ctor(auth)

    self.auth = auth
end

-- Handle an incoming request.
-- @param  \Illuminate\Http\Request request
-- @param  func next
-- @param  permissions
-- @return mixed

function _M:handle(request, next, permissions)

    if self.auth:guest() or not request:user():can(str.split(permissions, '|')) then
        abort(403)
    end
    
    return next(request)
end

return _M

