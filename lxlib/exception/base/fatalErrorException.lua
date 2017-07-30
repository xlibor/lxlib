
local _M = {
    _cls_    = '',
    _ext_    = 'errorException'
}

function _M:ctor(prev)

    self.msg = prev.msg
    self.file = prev.file
    self.line = prev.line
    self.trace = prev.trace
end

return _M

