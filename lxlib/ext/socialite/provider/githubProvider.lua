
local lx, _M, mt = oo{
    _cls_       = '',
    _ext_       = 'socialite.abstractProvider',
}

local app, lf, tb, str, new = lx.kit()
local try = lx.try

-- The scopes being requested.
-- @item table

function _M:ctor()

    self.scopes = {'user:email'}
end

-- {@inheritdoc}

function _M.__:getAuthUrl(state)

    return self:buildAuthUrlFromBase('https://github.com/login/oauth/authorize', state)
end

-- {@inheritdoc}

function _M.__:getTokenUrl()

    return 'https://github.com/login/oauth/access_token'
end

-- {@inheritdoc}

function _M.__:getUserByToken(token)

    local userUrl = 'https://api.github.com/user?access_token=' .. token:getToken()
    local response = self:getHttpClient():get(userUrl, self:getRequestOptions())
    local user = lf.jsde(response:getBody(), true)
    if tb.inList(self.scopes, 'user:email') then
        user['email'] = self:getEmailByToken(token)
    end
    
    return user
end

-- Get the email for the given access token.
-- @param  string  token
-- @return string|null

function _M.__:getEmailByToken(token)

    local emailsUrl = 'https://api.github.com/user/emails?access_token=' .. token:getToken()
    
    local response
    local ok, ret = try(function()
        response = self:getHttpClient():get(emailsUrl, self:getRequestOptions())
    end)
    :catch(function(e) 
    end)
    :run()

    if not ok then
        return
    end

    for _, email in ipairs(lf.jsde(response:getBody(), true)) do
        if email.primary and email.verified then
            return email.email
        end
    end
end

-- {@inheritdoc}

function _M.__:mapUserToObject(user)

    return new('socialite.user', {
        id = user.id,
        nickname = user.login,
        username = user.login,
        name = user.name,
        email = user.email,
        avatar = user.avatar_url
    })
end

-- Get the default options for an HTTP request.
-- @return table

function _M.__:getRequestOptions()

    return {headers = {Accept = 'application/vnd.github.v3+json'}}
end

return _M

