
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

function _M:match(route, req, includingMethod)

    if not includingMethod then
        return true
    end

    local method = req.method
    local methods = route.methodDict

    return methods[method] and true or false
end

return _M

