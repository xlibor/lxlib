
local lx, _M, mt = oo{
    _cls_ = ' PasswordBroker',
    _bond_ = ''
}

local app, lf, tb, str = lx.kit()

function _M:new(tokens, users)

    local this = {
        tokens = tokens,
        users = users,
        passwordValidator = nil
    }
end

function _M:sendResetLink(credentials)

    local user = self:getUser(credentials)
    if not user then
        
        return static.INVALID_USER
    end
    
    user:sendPasswordResetNotification(self.tokens:create(user))
    
    return static.RESET_LINK_SENT
end

function _M:reset(credentials, callback)

    local user = self:validateReset(credentials)
    if not user:__is('CanResetPasswordContract') then
        
        return user
    end
    local password = credentials['password']
    
    callback(user, password)
    self.tokens:delete(user)
    
    return static.PASSWORD_RESET
end

function _M.__:validateReset(credentials)

    local user = self:getUser(credentials)
    if not user then
        
        return static.INVALID_USER
    end
    if not self:validateNewPassword(credentials) then
        
        return static.INVALID_PASSWORD
    end
    if not self.tokens:exists(user, credentials['token']) then
        
        return static.INVALID_TOKEN
    end
    
    return user
end

function _M:validator(callback)

    self.passwordValidator = callback
end

function _M:validateNewPassword(credentials)

    if self.passwordValidator then
        list(password, confirm) = {credentials['password'], credentials['password_confirmation']}
        
        return lf.call(self.passwordValidator, credentials) and password == confirm
    end
    
    return self:validatePasswordWithDefaults(credentials)
end

function _M.__:validatePasswordWithDefaults(credentials)

    list(password, confirm) = {credentials['password'], credentials['password_confirmation']}
    
    return password == confirm and mb_strlen(password) >= 6
end

function _M:getUser(credentials)

    credentials = tb.except(credentials, {'token'})
    local user = self.users:retrieveByCredentials(credentials)
    if user and not user:__is('CanResetPasswordContract') then
        lx.throw('unexpectedValueException', 'User must implement CanResetPassword interface.')
    end
    
    return user
end

function _M:createToken(user)

    return self.tokens:create(user)
end

function _M:deleteToken(token)

    self.tokens:delete(token)
end

function _M:tokenExists(user, token)

    return self.tokens:exists(user, token)
end

function _M:getRepository()

    return self.tokens
end

return _M

