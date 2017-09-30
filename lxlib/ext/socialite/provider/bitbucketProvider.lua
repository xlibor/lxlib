
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'abstractProvider',
    _bond_ = 'providerInterface'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        scopes = {'email'},
        scopeSeparator = ' '
    }
    
    return oo(this, mt)
end

-- The scopes being requested.
-- @var table
-- The separating character for the requested scopes.
-- @var string
-- {@inheritdoc}

function _M.__:getAuthUrl(state)

    return self:buildAuthUrlFromBase('https://bitbucket.org/site/oauth2/authorize', state)
end

-- {@inheritdoc}

function _M.__:getTokenUrl()

    return 'https://bitbucket.org/site/oauth2/access_token'
end

-- {@inheritdoc}

function _M.__:getUserByToken(token)

    local userUrl = 'https://api.bitbucket.org/2.0/user?access_token=' .. token
    local response = self:getHttpClient():get(userUrl)
    local user = lf.jsde(response:getBody(), true)
    if tb.inList(self.scopes, 'email') then
        user['email'] = self:getEmailByToken(token)
    end
    
    return user
end

-- Get the email for the given access token.
-- @param  string  token
-- @return string|null

function _M.__:getEmailByToken(token)

    local emailsUrl = 'https://api.bitbucket.org/2.0/user/emails?access_token=' .. token
    try(function()
        response = self:getHttpClient():get(emailsUrl)
    end)
    :catch(function(Exception e) 
        
        return
    end)
    :run()
    local emails = lf.jsde(response:getBody(), true)
    for _, email in pairs(emails['values']) do
        if email['type'] == 'email' and email['is_primary'] and email['is_confirmed'] then
            
            return email['email']
        end
    end
end

-- {@inheritdoc}

function _M.__:mapUserToObject(user)

    return (new('user')):setRaw(user):map({
        id = user['uuid'],
        nickname = user['username'],
        name = tb.get(user, 'display_name'),
        email = tb.get(user, 'email'),
        avatar = tb.get(user, 'links.avatar.href')
    })
end

-- Get the access token for the given code.
-- @param  string  code
-- @return string

function _M:getAccessToken(code)

    local postKey = version_compare(ClientInterface.VERSION, '6') == 1 and 'form_params' or 'body'
    local response = self:getHttpClient():post(self:getTokenUrl(), {auth = {self.clientId, self.clientSecret}, headers = {Accept = 'application/json'}, postKey = self:getTokenFields(code)})
    
    return lf.jsde(response:getBody(), true)['access_token']
end

-- Get the POST fields for the token request.
-- @param  string  code
-- @return table

function _M.__:getTokenFields(code)

    return parent.getTokenFields(code) + {grant_type = 'authorization_code'}
end

return _M

