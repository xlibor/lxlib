
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'socialite.abstractProvider',
    -- _bond_ = 'providerInterface'
}

local app, lf, tb, str = lx.kit()

function _M:ctor()

    self.baseUrl = 'https://api.weixin.qq.com/sns'
    self.openId = nil
    self.scopes = {'snsapi_login'}
    self.stateless = true
    self._withCountryCode = false
    self._component = nil
end

-- Return country code instead of country name.
-- @return self

function _M:withCountryCode()

    self._withCountryCode = true
    
    return self
end

-- WeChat OpenPlatform 3rd component.
-- @param WeChatComponentInterface component
-- @return self

function _M:component(component)

    self.scopes = {'snsapi_base'}
    self._component = component
    
    return self
end

-- {@inheritdoc}.

function _M:getAccessToken(code)

    local response = self:getHttpClient():get(
        self:getTokenUrl(), {
            headers = {Accept = 'application/json'},
            query = self:getTokenFields(code)
        }
    )
    
    return self:parseAccessToken(response:getBody())
end

-- {@inheritdoc}.

function _M.__:getAuthUrl(state)

    local path = 'oauth2/authorize'
    if tb.inList(self.scopes, 'snsapi_login') then
        path = 'qrconnect'
    end
    
    return self:buildAuthUrlFromBase("https://open.weixin.qq.com/connect/" .. path, state)
end

-- {@inheritdoc}.

function _M.__:buildAuthUrlFromBase(url, state)

    local query = lf.httpBuildQuery(self:getCodeFields(state), '', '&')
    
    return url .. '?' .. query .. '#wechat_redirect'
end

-- {@inheritdoc}.

function _M.__:getCodeFields(state)

    if self._component then
        self:with({component_appid = self._component:getAppId()})
    end
    
    return tb.merge({
        appid = self.clientId,
        redirect_uri = self.redirectUrl,
        response_type = 'code',
        scope = self:formatScopes(self.scopes, self.scopeSeparator),
        state = state or lf.guid()
    }, self.parameters)
end

-- {@inheritdoc}.

function _M.__:getTokenUrl()

    if self._component then
        
        return self.baseUrl .. '/oauth2/component/access_token'
    end
    
    return self.baseUrl .. '/oauth2/access_token'
end

-- {@inheritdoc}.

function _M.__:getUserByToken(token)

    local scopes = str.split(token:getAttribute('scope', ''), ',')
    if tb.inList(scopes, 'snsapi_base') then
        
        return token:toArr()
    end
    if lf.isEmpty(token['openid']) then
        lx.throw('invalidArgumentException', 'openid of AccessToken is required.')
    end
    local language = self._withCountryCode and nil or (self.parameters['lang'] and self.parameters['lang'] or 'zh_CN')
    local response = self:getHttpClient():get(self.baseUrl .. '/userinfo', {query = tb.filter({access_token = token:getToken(), openid = token['openid'], lang = language})})
    
    return lf.jsde(response:getBody(), true)
end

-- {@inheritdoc}.

function _M.__:mapUserToObject(user)

    return new('socialite.user', {
        id = user.openid,
        name = user.nickname,
        nickname = user.nickname,
        avatar = user.headimgurl,
        email = nil
    })
end

-- {@inheritdoc}.

function _M.__:getTokenFields(code)

    return tb.filter({
        appid = self.clientId,
        secret = self.clientSecret,
        component_appid = self._component and self._component:getAppId() or nil,
        component_access_token = self._component and self._component:getToken() or nil,
        code = code,
        grant_type = 'authorization_code'
    })
end

-- Remove the fucking callback parentheses.
-- @param mixed response
-- @return string

function _M.__:removeCallback(response)

    if str.find(response, 'callback') then
        response = str.match(response, '%((.+)%)')
    end
    
    return response
end

return _M

