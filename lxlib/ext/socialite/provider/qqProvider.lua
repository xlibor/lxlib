
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'socialite.abstractProvider'
}

local app, lf, tb, str, new = lx.kit()

function _M:ctor()

    self.baseUrl = 'https://graph.qq.com'
    self.openId = nil
    self._withUnionId = false
    self.unionId = nil
    self.scopes = {'get_user_info'}
    self.uid = nil
end

function _M.__:getAuthUrl(state)

    return self:buildAuthUrlFromBase(self.baseUrl .. '/oauth2.0/authorize', state)
end

-- Get the token URL for the provider.
-- @return string

function _M.__:getTokenUrl()

    return self.baseUrl .. '/oauth2.0/token'
end

-- Get the Post fields for the token request.
-- @param string code
-- @return table

function _M.__:getTokenFields(code)

    local fields = self:__super(_M, 'getTokenFields', code)
    fields.grant_type = 'authorization_code'

    return fields
end

-- Get the access token for the given code.
-- @param string code
-- @return socialite.accessToken

function _M:getAccessToken(code)

    local response = self:getHttpClient():get(
        self:getTokenUrl(), {query = self:getTokenFields(code)}
    )

    return self:parseAccessToken(response:getBody())
end

-- Get the access token from the token response body.
-- @param string body
-- @return socialite.accessToken

function _M:parseAccessToken(body)

    local token = lf.parseStr(body)
    
    return self:__super(_M, 'parseAccessToken', token)
end

-- @return self

function _M:withUnionId()

    self._withUnionId = true
    
    return self
end

-- Get the raw user for the given access token.
-- @param socialite.accessToken token
-- @return table

function _M.__:getUserByToken(token)

    local url = self.baseUrl .. '/oauth2.0/me?access_token=' .. token:getToken()
    if self._withUnionId then
        url = url .. '&unionid=1'
    end
    local response = self:getHttpClient():get(url)
    local me = lf.jsde(self:removeCallback(response:getBody()))
    self.openId = me['openid']
    self.unionId = me['unionid'] or ''
    local queries = {access_token = token:getToken(), openid = self.openId, oauth_consumer_key = self.clientId}
    response = self:getHttpClient():get(self.baseUrl .. '/user/get_user_info?' .. lf.httpBuildQuery(queries))
    
    return lf.jsde(self:removeCallback(response:getBody()))
end

-- Map the raw user table to a Socialite User instance.
-- @param table user
-- @return socialite.user

function _M.__:mapUserToObject(user)

    return new('socialite.user', {
        id = self.openId,
        unionid = self.unionId,
        nickname = user.nickname,
        name = user.nickname,
        email = user.email,
        avatar = user.figureurl_qq_2
    })
end

-- Remove the fucking callback parentheses.
-- @param string response
-- @return string

function _M.__:removeCallback(response)

    if str.find(response, 'callback') then
        response = str.match(response, '%((.+)%)')
    end
    
    return response
end

return _M

