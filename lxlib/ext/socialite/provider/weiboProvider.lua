-- This file is part of the overtrue/socialite.
-- (c) overtrue <i@overtrue.me>
-- This source file is subject to the MIT license that is bundled
-- with this source code in the file LICENSE.

-- Class WeiboProvider.
-- @see http://open.weibo.com/wiki/%E6%8E%88%E6%9D%83%E6%9C%BA%E5%88%B6%E8%AF%B4%E6%98%8E [OAuth 2.0 授权机制说明]


local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'abstractProvider',
    _bond_ = 'providerInterface'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        baseUrl = 'https://api.weibo.com',
        version = '2',
        scopes = {'email'},
        uid = nil
    }
    
    return oo(this, mt)
end

-- The base url of Weibo API.
-- @var string
-- The API version for the request.
-- @var string
-- The scopes being requested.
-- @var table
-- The uid of user authorized.
-- @var int
-- Get the authentication URL for the provider.
-- @param string state
-- @return string

function _M.__:getAuthUrl(state)

    return self:buildAuthUrlFromBase(self.baseUrl .. '/oauth2/authorize', state)
end

-- Get the token URL for the provider.
-- @return string

function _M.__:getTokenUrl()

    return self.baseUrl .. '/' .. self.version .. '/oauth2/access_token'
end

-- Get the Post fields for the token request.
-- @param string code
-- @return table

function _M.__:getTokenFields(code)

    return parent.getTokenFields(code) + {grant_type = 'authorization_code'}
end

-- Get the raw user for the given access token.
-- @param \Overtrue\Socialite\AccessTokenInterface token
-- @return table

function _M.__:getUserByToken(token)

    local response = self:getHttpClient():get(self.baseUrl .. '/' .. self.version .. '/users/show.json', {query = {uid = token['uid'], access_token = token:getToken()}, headers = {Accept = 'application/json'}})
    
    return lf.jsde(response:getBody(), true)
end

-- Map the raw user table to a Socialite User instance.
-- @param table user
-- @return \Overtrue\Socialite\User

function _M.__:mapUserToObject(user)

    return new('user', {
        id = self:arrayItem(user, 'id'),
        nickname = self:arrayItem(user, 'screen_name'),
        name = self:arrayItem(user, 'name'),
        email = self:arrayItem(user, 'email'),
        avatar = self:arrayItem(user, 'avatar_large')
    })
end

return _M

