
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'controller',
    _mix_ = 'auth.resetPwd'
}

function _M:ctor()

    self.redirectTo = '/home'
    self:setBar('guest')
end

return _M

