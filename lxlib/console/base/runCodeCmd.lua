
local _M = { 
    _cls_ = '',
    _ext_ = 'command'
}

local mt = { __index = _M }

local lx = require('lxlib')
local app = lx.app()
 
function _M:ctor()

end

function _M:run()

    local code = self.args[1] or ''
    local bitCode = assert(loadstring(code))
    local env = {lx = lx}

    setmetatable(env, {__index = function(tb, k)
        return _G[k]
    end})

    setfenv(bitCode, env)
    
    bitCode()
end

return _M

