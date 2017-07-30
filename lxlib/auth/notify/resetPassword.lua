
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'notification'
}

local app, lf, tb, str = lx.kit()

function _M:new(token)

    local this = {
        token = token
    }

    return oo(this, mt)
end

function _M:via(notifiable)

    return {'mail'}
end

function _M:toMail(notifiable)

    return new('mailMessage'):line('You are receiving this email because we received a password reset request for your account.'):action('Reset Password', route('password.reset', self.token)):line('If you did not request a password reset, no further action is required.')
end

return _M

