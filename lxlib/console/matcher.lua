
local _M = { 
    _cls_ = ''
}

local mt = { __index = _M }

local lx = require('lxlib')
local app = lx.app()
 
function _M:new()

    local this = {
    }

    setmetatable(this, mt)

    return this
end

function _M:ctor()

end

return _M

