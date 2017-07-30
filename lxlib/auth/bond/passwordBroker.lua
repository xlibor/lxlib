local __ = {
    _cls_ = ''
}

const RESET_LINK_SENT = 'passwords.sent'

const PASSWORD_RESET = 'passwords.reset'

const INVALID_USER = 'passwords.user'

const INVALID_PASSWORD = 'passwords.password'

const INVALID_TOKEN = 'passwords.token'

function _M:sendResetLink(credentials) end

function _M:reset(credentials, callback) end

function _M:validator(callback) end

function _M:validateNewPassword(credentials) end

return __

