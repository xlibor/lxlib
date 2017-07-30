
local lx, _M = oo{ 
    _cls_     = '',
    _ext_     = 'httpException'
}

local app, lf, tb, str = lx.kit()

local supper = string.upper

function _M:ctor(curMethod, allow)

    self.statusCode = 405

    local allows = str.join(allow, ',')
    self.headers = {
        Allow = supper(allows)
    }
    self.msg = 'current method(' .. curMethod .. ') not allowd. allow:' .. allows
end

 
return _M

