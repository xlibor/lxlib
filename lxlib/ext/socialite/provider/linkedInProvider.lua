
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'abstractProvider',
    _bond_ = 'providerInterface'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        scopes = {'r_basicprofile', 'r_emailaddress'},
        scopeSeparator = ' ',
        fields = {'id', 'first-name', 'last-name', 'formatted-name', 'email-address', 'headline', 'location', 'industry', 'public-profile-url', 'picture-url', 'picture-urls::(original)'}
    }
    
    return oo(this, mt)
end

-- The scopes being requested.
-- @var table
-- The separating character for the requested scopes.
-- @var string
-- The fields that are included in the profile.
-- @var table
-- {@inheritdoc}

function _M.__:getAuthUrl(state)

    return self:buildAuthUrlFromBase('https://www.linkedin.com/oauth/v2/authorization', state)
end

-- {@inheritdoc}

function _M.__:getTokenUrl()

    return 'https://www.linkedin.com/oauth/v2/accessToken'
end

-- Get the POST fields for the token request.
-- @param  string  code
-- @return table

function _M.__:getTokenFields(code)

    return parent.getTokenFields(code) + {grant_type = 'authorization_code'}
end

-- {@inheritdoc}

function _M.__:getUserByToken(token)

    local fields = str.join(self.fields, ',')
    local url = 'https://api.linkedin.com/v1/people/~:(' .. fields .. ')'
    local response = self:getHttpClient():get(url, {headers = {['x-li-format'] = 'json', Authorization = 'Bearer ' .. token}})
    
    return lf.jsde(response:getBody(), true)
end

-- {@inheritdoc}

function _M.__:mapUserToObject(user)

    return (new('user')):setRaw(user):map({
        id = user['id'],
        nickname = nil,
        name = tb.get(user, 'formattedName'),
        email = tb.get(user, 'emailAddress'),
        avatar = tb.get(user, 'pictureUrl'),
        avatar_original = tb.get(user, 'pictureUrls.values.0')
    })
end

-- Set the user fields to request from LinkedIn.
-- @param  table  fields
-- @return self

function _M:fields(fields)

    self.fields = fields
    
    return self
end

return _M

