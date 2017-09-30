-- This file is part of the overtrue/socialite.
-- (c) overtrue <i@overtrue.me>
-- This source file is subject to the MIT license that is bundled
-- with this source code in the file LICENSE.

-- Class WeChatProvider.
-- @see https://open.weixin.qq.com/cgi-bin/showdocument?action=dir_list&t=resource/res_list&verify=1&id=open1419318590&token=&lang=zh_CN [WeChat - 公众开放平台代公众号 OAuth 文档]


local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'weChatProvider'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        componentAppId = nil,
        componentAccessToken = nil,
        credentials = nil,
        scopes = {'snsapi_base'}
    }
    
    return oo(this, mt)
end

-- Component AppId.
-- @deprecated 2.0 Will be removed in the future
-- @var string
-- Component Access Token.
-- @deprecated 2.0 Will be removed in the future
-- @var string
-- @var \EasyWeChat\OpenPlatform\AccessToken|array
-- {@inheritdoc}.
-- Create a new provider instance.
-- (Overriding).
-- @param \Symfony\Component\HttpFoundation\Request  request
-- @param string                                     clientId
-- @param \EasyWeChat\OpenPlatform\AccessToken|array credentials
-- @param string|null                                redirectUrl

function _M:ctor(request, clientId, credentials, redirectUrl)

    parent.__construct(request, clientId, nil, redirectUrl)
    self.credentials = credentials
    if lf.isTbl(credentials) then
        local self.componentAppId, self.componentAccessToken = unpack(credentials)
    end
end

-- {@inheritdoc}.

function _M:getCodeFields(state)

    self:with({component_appid = self:componentAppId()})
    
    return parent.getCodeFields(state)
end

-- {@inheritdoc}.

function _M.__:getTokenUrl()

    return self.baseUrl .. '/oauth2/component/access_token'
end

-- {@inheritdoc}.

function _M.__:getTokenFields(code)

    return {
        appid = self.clientId,
        component_appid = self:componentAppId(),
        component_access_token = self:componentAccessToken(),
        code = code,
        grant_type = 'authorization_code'
    }
end

-- Get component app id.
-- @return string

function _M.__:componentAppId()

    return self.componentAppId or self.credentials:getAppId()
end

-- Get component access token.
-- @return string

function _M.__:componentAccessToken()

    return self.componentAccessToken or self.credentials:getToken()
end

return _M

