
local _M = { 
    _cls_     = ''
}

local mt = { __index = _M }

local sfind = string.find

function _M:new()

    local this = {
    }
    
    setmetatable(this, mt)

    return this
end

function _M:match(route, req)

    local compiled = route.compiled
    local pattern = compiled.hostRegex

    local host = req.host
    if host ~= '' and pattern ~= '' then

        local hostMatched = sfind(host, pattern)

        return hostMatched
    end

    return true
end

return _M

