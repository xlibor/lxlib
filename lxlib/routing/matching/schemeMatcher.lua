
local _M = { 
    _cls_     = ''
}

local mt = { __index = _M }

function _M:new()

    local this = {
    }
    
    setmetatable(this, mt)

    return this
end

function _M:match(route, req)
    
    if route:httpOnly() then
        return not req.isSecure
    elseif route:secure() then
        return req.isSecure
    end

    return true
end

return _M

