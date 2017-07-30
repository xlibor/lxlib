
local _M = {
    _cls_ = ''
}

local mt = {__index = _M}

function _M:new(value)
    
    local this = {
        value = value
    }

    setmetatable(this, mt)

    return this
end

function _M:getValue(value)

    return self.value
end

function _M:toStr()
    
    return tostring(self.value)
end

return _M

