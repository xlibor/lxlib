local _M = {
    _cls_ = ''
}
local mt = { __index = _M }

local lx = require('lxlib')
local ckBase = require('lxlib.cookie.base.utils')

function _M:new()
    local this = {
        items = lx.n.obj(),
        base = ckBase:new()
    }

    setmetatable(this, mt)
 
    return this
end

function _M:get(key)
    
    return self.base:get(key)
end

function _M:set(...)
    
    local ck = self.base

    local args = {...}
    local p1 = args[1]
    local p1type = type(p1)
    if p1type == 'string' then 
        local expires = args[3]
        if expires then
            expires = tonumber(expires)
            args[3] = ngx.cookie_time(os.time() + expires)
        end

        ck:set( {key = args[1], value = args[2], expires = args[3], path='/'} )
    elseif p1type == 'table' then
        local maxAge = -1
        p1.expires = p1.expire
        local expires = p1.expires
        p1.key = p1.name
 
        if expires then
            expires = tonumber(expires)
            if expires == 0 then
                maxAge = -1
            elseif expires > 0 then 
                maxAge = expires * 60
            elseif expires < 0 then
                maxAge = 0 
            end
            if maxAge < 0 then
                p1.expires = nil
            else
                p1.expires = ngx.cookie_time(os.time() + expires * 60)
                p1.max_age = maxAge
            end
        end
 
        ck:set(p1)
    else

    end

end

function _M:all()

    return self.base:get_all() or {}
end

return _M

