
local lx, _M, mt = oo{ 
    _cls_     = '',
    _ext_     = 'httpException'
}

function _M:new(msg, code, prev)

    local this = {
        msg         = msg,
        prev        = prev,
        code        = code or 0
    }
    
    return oo(this, mt)
end

function _M:ctor()

    self.statusCode = 404
    self.headers = {}
end

function _M:getResponse()

    return self.response
end
 
return _M

