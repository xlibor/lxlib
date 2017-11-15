
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'manager'
}

local app, lf, tb, str, new = lx.kit()

function _M:ctor()

    self.inCtx = true
end
-- Get a driver instance.
-- @param  string  driver
-- @return mixed

function _M:with(driver)

    return self:resolve(driver)
end

-- Create an instance of the github driver.
-- @return socialite.abstractProvider

function _M:createGithubDriver(config)

    return self:buildProvider('socialite.githubProvider', config)
end

-- Create an instance of the wechat driver.
-- @return socialite.abstractProvider

function _M:createWechatDriver(config)

    return self:buildProvider('socialite.wechatProvider', config)
end

-- Create an instance of the qq driver.
-- @return socialite.abstractProvider

function _M:createQqDriver(config)

    return self:buildProvider('socialite.qqProvider', config)
end

-- Create an instance of the specified driver.
-- @return socialite.abstractProvider

function _M.__:createFacebookDriver()

    local config = app:conf('services.facebook')
    
    return self:buildProvider('socialite.facebookProvider', config)
end

-- Create an instance of the specified driver.
-- @return socialite.abstractProvider

function _M.__:createGoogleDriver()

    local config = app:conf('services.google')
    
    return self:buildProvider('socialite.googleProvider', config)
end

-- Create an instance of the specified driver.
-- @return socialite.abstractProvider

function _M.__:createLinkedinDriver()

    local config = app:conf('services.linkedin')
    
    return self:buildProvider('socialite.linkedInProvider', config)
end

-- Create an instance of the specified driver.
-- @return socialite.abstractProvider

function _M.__:createBitbucketDriver()

    local config = app:conf('services.bitbucket')
    
    return self:buildProvider('socialite.bitbucketProvider', config)
end

-- Build an OAuth2 provider instance.
-- @param  string  provider
-- @param  table  config
-- @return socialite.abstractProvider

function _M:buildProvider(provider, config)

    return new(provider,
        app:get('request'), config.client_id, config.client_secret,
        self:formatRedirectUrl(config),
        tb.get(config, 'httpInfo', {})
    )
end

-- Format the server configuration.
-- @param  table  config
-- @return table

function _M:formatConfig(config)

    return tb.merge(
        {
            identifier = config.client_id,
            secret = config.client_secret,
            callback_uri = self:formatRedirectUrl(config)
        },
        config
    )
end

-- Format the callback URL, resolving a relative URI if needed.
-- @param  table  config
-- @return string

function _M.__:formatRedirectUrl(config)

    local redirect = lf.value(config.redirect)
    
    return str.startsWith(redirect, '/') and app.url:to(redirect) or redirect
end

function _M.__:getConfig(name)

    return app:conf('services.' .. name)
end

-- Get the default driver name.
-- @return string

function _M:getDefaultDriver()

    lx.throw('invalidArgumentException', 'No Socialite driver was specified.')
end

return _M

