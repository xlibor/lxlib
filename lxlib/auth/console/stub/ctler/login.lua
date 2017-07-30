
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'controller',
    _mix_ = 'auth.authenticateUser'
}

function _M:ctor()

    self.redirectTo = '/home'
    self:setBar('guest', {except = 'logout'})
end

return _M

