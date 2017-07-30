
local _M = { 
    _cls_     = '',
    _ext_     = {
        from = 'viewException'
    }
}

local mt = { __index = _M }

function _M:ctor(view, err)
    
    self.view = view

    if err then
        self.msg = err
    else
        self.msg = view .. ' not exists'
    end
end


return _M

