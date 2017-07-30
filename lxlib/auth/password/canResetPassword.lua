
local lx, _M = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

function _M:getEmailForPasswordReset()

    return self.email
end

function _M:sendPasswordResetNotification(token)

    self:notify(new('resetPasswordNotification',token))
end

return _M

