
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'abstractProvider',
    _bond_ = 'providerInterface'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        graphUrl = 'https://graph.facebook.com',
        version = 'v2.10',
        fields = {'name', 'email', 'gender', 'verified', 'link'},
        scopes = {'email'},
        popup = false,
        reRequest = false
    }
    
    return oo(this, mt)
end

-- The base Facebook Graph URL.
-- @var string
-- The Graph API version for the request.
-- @var string
-- The user fields being requested.
-- @var table
-- The scopes being requested.
-- @var table
-- Display the dialog in a popup view.
-- @var bool
-- Re-request a declined permission.
-- @var bool
-- {@inheritdoc}

function _M.__:getAuthUrl(state)

    return self:buildAuthUrlFromBase('https://www.facebook.com/' .. self.version .. '/dialog/oauth', state)
end

-- {@inheritdoc}

function _M.__:getTokenUrl()

    return self.graphUrl .. '/' .. self.version .. '/oauth/access_token'
end

-- {@inheritdoc}

function _M:getAccessTokenResponse(code)

    local postKey = version_compare(ClientInterface.VERSION, '6') == 1 and 'form_params' or 'body'
    local response = self:getHttpClient():post(self:getTokenUrl(), {postKey = self:getTokenFields(code)})
    local data = {}
    data = lf.jsde(response:getBody(), true)
    
    return tb.add(data, 'expires_in', tb.pull(data, 'expires'))
end

-- {@inheritdoc}

function _M.__:getUserByToken(token)

    local appSecretProof
    local meUrl = self.graphUrl .. '/' .. self.version .. '/me?access_token=' .. token .. '&fields=' .. str.join(self.fields, ',')
    if not lf.isEmpty(self.clientSecret) then
        appSecretProof = hash_hmac('sha256', token, self.clientSecret)
        meUrl = meUrl .. '&appsecret_proof=' .. appSecretProof
    end
    local response = self:getHttpClient():get(meUrl, {headers = {Accept = 'application/json'}})
    
    return lf.jsde(response:getBody(), true)
end

-- {@inheritdoc}

function _M.__:mapUserToObject(user)

    local avatarUrl = self.graphUrl .. '/' .. self.version .. '/' .. user['id'] .. '/picture'
    
    return (new('user')):setRaw(user):map({
        id = user['id'],
        nickname = nil,
        name = user['name'] and user['name'] or nil,
        email = user['email'] and user['email'] or nil,
        avatar = avatarUrl .. '?type=normal',
        avatar_original = avatarUrl .. '?width=1920',
        profileUrl = user['link'] and user['link'] or nil
    })
end

-- {@inheritdoc}

function _M.__:getCodeFields(state)

    local fields = parent.getCodeFields(state)
    if self.popup then
        fields['display'] = 'popup'
    end
    if self.reRequest then
        fields['auth_type'] = 'rerequest'
    end
    
    return fields
end

-- Set the user fields to request from Facebook.
-- @param  table  fields
-- @return self

function _M:fields(fields)

    self.fields = fields
    
    return self
end

-- Set the dialog to be displayed as a popup.
-- @return self

function _M:asPopup()

    self.popup = true
    
    return self
end

-- Re-request permissions which were previously declined.
-- @return self

function _M:reRequest()

    self.reRequest = true
    
    return self
end

return _M

