
local _M = { 
    _cls_    = '',
    _ext_     = 'viewException'
}

local mt = { __index = _M }

function _M:ctor(view)
    
    self.view = view
    self.msg = view .. ' not exists'
end


return _M