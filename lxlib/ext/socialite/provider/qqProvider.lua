-- This file is part of the overtrue/socialite.
-- (c) overtrue <i@overtrue.me>
-- This source file is subject to the MIT license that is bundled
-- with this source code in the file LICENSE.

-- Class QQProvider.
-- @see http://wiki.connect.qq.com/oauth2-0%E7%AE%80%E4%BB%8B [QQ - OAuth 2.0 登录QQ]


local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'abstractProvider',
    _bond_ = 'providerInterface'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        baseUrl = 'https://graph.qq.com',
        openId = nil,
        withUnionId = false,
        unionId = nil,
        scopes = {'get_user_info'},
        uid = nil
    }
    
    return oo(this, mt)
end

-- The base url of QQ API.
-- @var string
-- User openid.
-- @var string
-- get token(openid) with unionid.
-- @var bool
-- User unionid.
-- @var string
-- The scopes being requested.
-- @var table
-- The uid of user authorized.
-- @var int
-- Get the authentication URL for the provider.
-- @param string state
-- @return string

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

    return parent.getTokenFields(code) + {grant_type = 'authorization_code'}
end

-- Get the access token for the given code.
-- @param string code
-- @return \Overtrue\Socialite\AccessToken

function _M:getAccessToken(code)

    local response = self:getHttpClient():get(self:getTokenUrl(), {query = self:getTokenFields(code)})
    
    return self:parseAccessToken(response:getBody():getContents())
end

-- Get the access token from the token response body.
-- @param string body
-- @return \Overtrue\Socialite\AccessToken

function _M:parseAccessToken(body)

    parse_str(body, token)
    
    return parent.parseAccessToken(token)
end

-- @return self

function _M:withUnionId()

    self.withUnionId = true
    
    return self
end

-- Get the raw user for the given access token.
-- @param \Overtrue\Socialite\AccessTokenInterface token
-- @return table

function _M.__:getUserByToken(token)

    local url = self.baseUrl .. '/oauth2.0/me?access_token=' .. token:getToken()
    self.withUnionId and (url = url .. '&unionid=1')
    local response = self:getHttpClient():get(url)
    local me = lf.jsde(self:removeCallback(response:getBody():getContents()), true)
    self.openId = me['openid']
    self.unionId = me['unionid'] and me['unionid'] or ''
    local queries = {access_token = token:getToken(), openid = self.openId, oauth_consumer_key = self.clientId}
    response = self:getHttpClient():get(self.baseUrl .. '/user/get_user_info?' .. lf.httpBuildQuery(queries))
    
    return lf.jsde(self:removeCallback(response:getBody():getContents()), true)
end

-- Map the raw user table to a Socialite User instance.
-- @param table user
-- @return \Overtrue\Socialite\User

function _M.__:mapUserToObject(user)

    return new('user', {
        id = self.openId,
        unionid = self.unionId,
        nickname = self:arrayItem(user, 'nickname'),
        name = self:arrayItem(user, 'nickname'),
        email = self:arrayItem(user, 'email'),
        avatar = self:arrayItem(user, 'figureurl_qq_2')
    })
end

-- Remove the fucking callback parentheses.
-- @param string response
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

