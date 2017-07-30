
local _M = { 
    _cls_     = '',
    _ext_     = 'runtimeException'
}

function _M:ctor(model)

    self.msg = 'no query results for model [' .. model .. ']'
end

return _M

