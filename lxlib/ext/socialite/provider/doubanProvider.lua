-- This file is part of the overtrue/socialite.
-- (c) overtrue <i@overtrue.me>
-- This source file is subject to the MIT license that is bundled
-- with this source code in the file LICENSE.

-- Class DoubanProvider.
-- @see http://developers.douban.com/wiki/?title=oauth2 [使用 OAuth 2.0 访问豆瓣 API]


local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'abstractProvider',
    _bond_ = 'providerInterface'
}

local app, lf, tb, str = lx.kit()

-- {@inheritdoc}.

function _M.__:getAuthUrl(state)

    return self:buildAuthUrlFromBase('https://www.douban.com/service/auth2/auth', state)
end

-- {@inheritdoc}.

function _M.__:getTokenUrl()

    return 'https://www.douban.com/service/auth2/token'
end

-- {@inheritdoc}.

function _M.__:getUserByToken(token)

    local response = self:getHttpClient():get('https://api.douban.com/v2/user/~me', {headers = {Authorization = 'Bearer ' .. token:getToken()}})
    
    return lf.jsde(response:getBody():getContents(), true)
end

-- {@inheritdoc}.

function _M.__:mapUserToObject(user)

    return new('user', {
        id = self:arrayItem(user, 'id'),
        nickname = self:arrayItem(user, 'name'),
        name = self:arrayItem(user, 'name'),
        avatar = self:arrayItem(user, 'large_avatar'),
        email = nil
    })
end

-- {@inheritdoc}.

function _M.__:getTokenFields(code)

    return parent.getTokenFields(code) + {grant_type = 'authorization_code'}
end

-- {@inheritdoc}.

function _M:getAccessToken(code)

    local response = self:getHttpClient():post(self:getTokenUrl(), {form_params = self:getTokenFields(code)})
    
    return self:parseAccessToken(response:getBody():getContents())
end

return _M

