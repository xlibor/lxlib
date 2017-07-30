
local _M = {
    _cls_ = '@sqlFieldValue'
}
local mt = { __index = _M }

local pub = require('lxlib.db.pub')

function _M:new(name, value)
    local this = {
        name = name,
        value = value
    }
    
    setmetatable(this, mt)

    return this
end

 
return _M