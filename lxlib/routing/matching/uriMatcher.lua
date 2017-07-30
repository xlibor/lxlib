
local lx, _M, mt = oo{ 
    _cls_     = ''
}

local sfind, ssub = string.find, string.sub

function _M:new()

    local this = {
    }
    
    oo(this, mt)

    return this
end

function _M:match(route, req)

    local compiled = route.compiled
    local pattern = compiled.pathRegex

    local path = req.path
    if ssub(path, 1, 1) ~= '/' then
        path = '/' .. path
    end

    local pathMatched = sfind(path, pattern)

    return pathMatched
end

return _M

