
local _M = { 
    _cls_     = '',
    _ext_     = {
        from = 'runtimeException'
    }
}

local mt = { __index = _M }

function _M:ctor()
    
    self.errorInfo = {}
end


return _M

