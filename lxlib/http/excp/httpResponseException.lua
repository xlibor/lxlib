
local _M = { 
    _cls_     = '',
    _ext_     = 'runtimeException'
}

local mt = { __index = _M }

function _M:new(response)
    
    local this = {
        response = response
    }
    
    setmetatable(this, mt)
 
    return this
end

function _M:ctor(response)

    self.msg = response:getContent()
end

function _M:getResponse()

    return self.response
end
 
return _M

