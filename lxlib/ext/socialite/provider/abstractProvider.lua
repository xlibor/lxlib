
local lx, _M, mt = oo{
    _cls_ = '',
    _bond_ = 'socialite.providerBond',
    a__ = {}
}

local app, lf, tb, str, new = lx.kit()

function _M:new(request, clientId, clientSecret, redirectUrl, httpInfo)

    local this = {
        request = request,
        httpClient = nil,
        clientId = clientId,
        clientSecret = clientSecret,
        redirectUrl = redirectUrl,
        parameters = {},
        scopes = {},
        scopeSeparator = ',',
        encodingType = PHP_QUERY_RFC1738,
        stateless = false,
        httpInfo = httpInfo or {}
    }
    
    return oo(this, mt)
end

-- Get the authentication URL for the provider.
-- @param  string  state
-- @return string

function _M.a__:getAuthUrl(state) end

-- Get the token URL for the provider.
-- @return string

function _M.a__:getTokenUrl() end

-- Get the raw user for the given access token.
-- @param  string  token
-- @return table

function _M.a__:getUserByToken(token) end

-- Map the raw user table to a Socialite User instance.
-- @param  table  user
-- @return socialite.userBond

function _M.a__:mapUserToObject(user) end

-- Redirect the user of the application to the provider's authentication screen.
-- @return redirectResponse

function _M:redirect()

    local state
    if self:usesState() then
        state = self:getState()
        self.request.session:put('state', state)
    end
    
    return new('redirectResponse', self:getAuthUrl(state))
end

-- Get the authentication URL for the provider.
-- @param  string  url
-- @param  string  state
-- @return string

function _M.__:buildAuthUrlFromBase(url, state)

    return url .. '?' .. lf.httpBuildQuery(self:getCodeFields(state))
end

-- Get the GET parameters for the code request.
-- @param  string|null  state
-- @return table

function _M.__:getCodeFields(state)

    local fields = {
        client_id = self.clientId,
        redirect_uri = self.redirectUrl,
        scope = self:formatScopes(self:getScopes(), self.scopeSeparator),
        response_type = 'code'
    }
    if self:usesState() then
        fields.state = state
    end
    
    return tb.merge(fields, self.parameters)
end

-- Format the given scopes.
-- @param  table  scopes
-- @param  string  scopeSeparator
-- @return string

function _M.__:formatScopes(scopes, scopeSeparator)

    return str.join(scopes, scopeSeparator)
end

-- {@inheritdoc}

function _M:user()

    if self:hasInvalidState() then
        lx.throw('socialite.invalidStateException')
    end
    local response = self:getAccessTokenResponse(self:getCode())
    local token = tb.get(response, 'access_token')
    local user = self:mapUserToObject(self:getUserByToken(token))
    
    return user:setToken(token)
        :setRefreshToken(tb.get(response, 'refresh_token'))
        :setExpiresIn(tb.get(response, 'expires_in'))
end

-- Get a Social User instance from a known access token.
-- @param  string  token
-- @return socialite.userBond

function _M:userFromToken(token)

    local user = self:mapUserToObject(self:getUserByToken(token))
    
    return user:setToken(token)
end

-- Determine if the current request / session has a mismatching "state".
-- @return bool

function _M.__:hasInvalidState()

    if self:isStateless() then

        return false
    end
    local state = self.request.session:pull('state')

    return not (str.len(state) > 0 and self.request:input('state') == state)
end

-- Get the access token response for the given code.
-- @param  string  code
-- @return table

function _M:getAccessTokenResponse(code)

    local response = self:getHttpClient()
        :post(self:getTokenUrl(), {
                headers = {Accept = 'application/json'},
                body = self:getTokenFields(code)
            }
        )

    return lf.jsde(response:getBody(), true)
end

-- Get the POST fields for the token request.
-- @param  string  code
-- @return table

function _M.__:getTokenFields(code)

    return {
        client_id = self.clientId,
        client_secret = self.clientSecret,
        code = code,
        redirect_uri = self.redirectUrl
    }
end

-- Get the code from the request.
-- @return string

function _M.__:getCode()

    return self.request:input('code')
end

-- Merge the scopes of the requested access.
-- @param  table|string  scopes
-- @return self

function _M:scopes(scopes)

    self.scopes = tb.unique(tb.merge(self.scopes, lf.needList(scopes)))
    
    return self
end

-- Set the scopes of the requested access.
-- @param  table|string  scopes
-- @return self

function _M:setScopes(scopes)

    self.scopes = tb.unique(lf.needList(scopes))
    
    return self
end

-- Get the current scopes.
-- @return table

function _M:getScopes()

    return self.scopes
end

-- Set the redirect URL.
-- @param  string  url
-- @return self

function _M:redirectUrl(url)

    self.redirectUrl = url
    
    return self
end

-- Get a instance of the http client.
-- @return net.http.client

function _M.__:getHttpClient()

    if not self.httpClient then
        self.httpClient = new('net.http.client', self.httpInfo)
    end
    
    return self.httpClient
end

-- Set the http client instance.
-- @param  net.http.client  client
-- @return self

function _M:setHttpClient(client)

    self.httpClient = client
    
    return self
end

-- Set the request instance.
-- @param  request  request
-- @return self

function _M:setRequest(request)

    self.request = request
    
    return self
end

-- Determine if the provider is operating with state.
-- @return bool

function _M.__:usesState()

    return not self.stateless
end

-- Determine if the provider is operating as stateless.
-- @return bool

function _M.__:isStateless()

    return self.stateless
end

-- Indicates that the provider should operate as stateless.
-- @return self

function _M:setStateless()

    self.stateless = true
    
    return self
end

-- Get the string used for session state.
-- @return string

function _M.__:getState()

    return str.random(40)
end

-- Set the custom parameters of the request.
-- @param  table  parameters
-- @return self

function _M:with(parameters)

    self.parameters = parameters
    
    return self
end

return _M

