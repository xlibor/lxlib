
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'abstractProvider',
    _bond_ = 'providerInterface'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        scopeSeparator = ' ',
        scopes = {'openid', 'profile', 'email'}
    }
    
    return oo(this, mt)
end

-- The separating character for the requested scopes.
-- @var string
-- The scopes being requested.
-- @var table
-- {@inheritdoc}

function _M.__:getAuthUrl(state)

    return self:buildAuthUrlFromBase('https://accounts.google.com/o/oauth2/auth', state)
end

-- {@inheritdoc}

function _M.__:getTokenUrl()

    return 'https://accounts.google.com/o/oauth2/token'
end

-- Get the POST fields for the token request.
-- @param  string  code
-- @return table

function _M.__:getTokenFields(code)

    return array_add(parent.getTokenFields(code), 'grant_type', 'authorization_code')
end

-- {@inheritdoc}

function _M.__:getUserByToken(token)

    local response = self:getHttpClient():get('https://www.googleapis.com/plus/v1/people/me?', {query = {prettyPrint = 'false'}, headers = {Accept = 'application/json', Authorization = 'Bearer ' .. token}})
    
    return lf.jsde(response:getBody(), true)
end

-- {@inheritdoc}

function _M.__:mapUserToObject(user)

    return (new('user')):setRaw(user):map({
        id = user['id'],
        nickname = tb.get(user, 'nickname'),
        name = user['displayName'],
        email = user['emails'][0]['value'],
        avatar = tb.get(user, 'image')['url'],
        avatar_original = str.rereplace(tb.get(user, 'image')['url'], '/\\?sz=([0-9]+)/', '')
    })
end

return _M

