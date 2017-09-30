-- This file is part of the overtrue/socialite.
-- (c) overtrue <i@overtrue.me>
-- This source file is subject to the MIT license that is bundled
-- with this source code in the file LICENSE.
-- Class WeChatProvider.
-- @see http://mp.weixin.qq.com/wiki/9/01f711493b5a02f24b04365ac5d8fd95.html [WeChat - 公众平台OAuth文档]
-- @see https://open.weixin.qq.com/cgi-bin/showdocument?action=dir_list&t=resource/res_list&verify=1&id=open1419316505&token=&lang=zh_CN [网站应用微信登录开发指南]


local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'abstractProvider',
    _bond_ = 'providerInterface'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        baseUrl = 'https://api.weixin.qq.com/sns',
        openId = nil,
        scopes = {'snsapi_login'},
        stateless = true,
        withCountryCode = false,
        component = nil
    }
    
    return oo(this, mt)
end

-- The base url of WeChat API.
-- @var string
-- {@inheritdoc}.
-- {@inheritdoc}.
-- Indicates if the session state should be utilized.
-- @var bool
-- Return country code instead of country name.
-- @var bool
-- @var WeChatComponentInterface
-- Return country code instead of country name.
-- @return self

function _M:withCountryCode()

    self.withCountryCode = true
    
    return self
end

-- WeChat OpenPlatform 3rd component.
-- @param WeChatComponentInterface component
-- @return self

function _M:component(component)

    self.scopes = {'snsapi_base'}
    self.component = component
    
    return self
end

-- {@inheritdoc}.

function _M:getAccessToken(code)

    local response = self:getHttpClient():get(self:getTokenUrl(), {headers = {Accept = 'application/json'}, query = self:getTokenFields(code)})
    
    return self:parseAccessToken(response:getBody())
end

-- {@inheritdoc}.

function _M.__:getAuthUrl(state)

    local path = 'oauth2/authorize'
    if tb.inList(self.scopes, 'snsapi_login') then
        path = 'qrconnect'
    end
    
    return self:buildAuthUrlFromBase("https://open.weixin.qq.com/connect/{path}", state)
end

-- {@inheritdoc}.

function _M.__:buildAuthUrlFromBase(url, state)

    local query = lf.httpBuildQuery(self:getCodeFields(state), '', '&', self.encodingType)
    
    return url .. '?' .. query .. '#wechat_redirect'
end

-- {@inheritdoc}.

function _M.__:getCodeFields(state)

    if self.component then
        self:with({component_appid = self.component:getAppId()})
    end
    
    return tb.merge({
        appid = self.clientId,
        redirect_uri = self.redirectUrl,
        response_type = 'code',
        scope = self:formatScopes(self.scopes, self.scopeSeparator),
        state = state or md5(time())
    }, self.parameters)
end

-- {@inheritdoc}.

function _M.__:getTokenUrl()

    if self.component then
        
        return self.baseUrl .. '/oauth2/component/access_token'
    end
    
    return self.baseUrl .. '/oauth2/access_token'
end

-- {@inheritdoc}.

function _M.__:getUserByToken(token)

    local scopes = str.split(token:getAttribute('scope', ''), ',')
    if tb.inList(scopes, 'snsapi_base') then
        
        return token:toArray()
    end
    if lf.isEmpty(token['openid']) then
        lx.throw(InvalidArgumentException, 'openid of AccessToken is required.')
    end
    local language = self.withCountryCode and nil or (self.parameters['lang'] and self.parameters['lang'] or 'zh_CN')
    local response = self:getHttpClient():get(self.baseUrl .. '/userinfo', {query = tb.filter({access_token = token:getToken(), openid = token['openid'], lang = language})})
    
    return lf.jsde(response:getBody(), true)
end

-- {@inheritdoc}.

function _M.__:mapUserToObject(user)

    return new('user', {
        id = self:arrayItem(user, 'openid'),
        name = self:arrayItem(user, 'nickname'),
        nickname = self:arrayItem(user, 'nickname'),
        avatar = self:arrayItem(user, 'headimgurl'),
        email = nil
    })
end

-- {@inheritdoc}.

function _M.__:getTokenFields(code)

    return tb.filter({
        appid = self.clientId,
        secret = self.clientSecret,
        component_appid = self.component and self.component:getAppId() or nil,
        component_access_token = self.component and self.component:getToken() or nil,
        code = code,
        grant_type = 'authorization_code'
    })
end

-- Remove the fucking callback parentheses.
-- @param mixed response
-- @return string

function _M.__:removeCallback(response)

    local rpos
    local lpos
    if str.strpos(response, 'callback') ~= false then
        lpos = str.strpos(response, '(')
        rpos = strrpos(response, ')')
        response = str.substr(response, lpos + 1, rpos - lpos - 1)
    end
    
    return response
end

return _M

