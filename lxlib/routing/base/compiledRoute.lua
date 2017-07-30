
local _M = {
    _cls_ = ''
}

local mt = { __index = _M }

function _M:new(pathPre, pathRegex, pathTokens, pathVars, hostRegex, hostTokens, hostVars, vars)
    
    local this = {
        vars = vars or {},
        pathPre = pathPre or 'testPathPre',
        pathRegex = pathRegex or '',
        pathTokens = pathTokens or {},
        pathVars = pathVars or {},
        hostRegex = hostRegex or '',
        hostTokens = hostTokens or {},
        hostVars = hostVars or {}
    }

    setmetatable(this, mt)

    return this
end

return _M

