
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

function _M:new(routes)

    local this = {
        routes = routes,
        forcedRoot = nil,
        _forceSchema = nil,
        cachedRoot = nil,
        cachedSchema = nil,
        rootNamespace = nil,
        dontEncode = {
            ['%2F'] = '/',
            ['%40'] = '@',
            ['%3A'] = ':',
            ['%3B'] = ';',
            ['%2C'] = ',',
            ['%3D'] = '=',
            ['%2B'] = '+',
            ['%21'] = '!',
            ['%2A'] = '*',
            ['%7C'] = '|',
            ['%3F'] = '?',
            ['%26'] = '&',
            ['%23'] = '#',
            ['%25'] = '%'
        }
    }

    return oo(this, mt)
end

function _M:ctor(routes)

end

function _M:full()

    return self:getRequest().fullUrl
end

function _M:current()

    return self:to(self:getRequest().url)
end

function _M:previous(fallback)

    fallback = fallback or false
    local referrer = self:getRequest().headers:get('referer')

    local url = referrer and self:to(referrer) or self:getPreviousUrlFromSession()

    if url then
        
        return url
    elseif fallback then
        
        return self:to(fallback)
    else 
        
        return self:to('/')
    end
end

function _M:to(path, extra, secure)

    extra = extra or {}
    local query
    
    if self:isValidUrl(path) then
        
        return path
    end
    local scheme = self:getScheme(secure)
    extra = self:formatParameters(extra)
    local tail = str.join(tb.map(extra, lf.rawurlencode), '/')
    
    local root = self:getRootUrl(scheme)

    local queryPosition = str.strpos(path, '%?')
    if queryPosition then
        query = str.substr(path, queryPosition)
        path = str.substr(path, 1, queryPosition)
    else 
        query = ''
    end
    
    return self:trimUrl(root, path, tail) .. query
end

function _M:secure(path, parameters)

    parameters = parameters or {}
    
    return self:to(path, parameters, true)
end

function _M:asset(path, secure)

    if self:isValidUrl(path) then
        
        return path
    end
    
    local root = self:getRootUrl(self:getScheme(secure))
    
    return self:removeIndex(root) .. '/' .. str.trim(path, '/')
end

function _M:assetFrom(root, path, secure)

    root = self:getRootUrl(self:getScheme(secure), root)
    
    return self:removeIndex(root) .. '/' .. str.trim(path, '/')
end

function _M.__:removeIndex(root)

    local i = 'index'
    
    return str.contains(root, i) and str.replace(root, '/' .. i, '') or root
end

function _M:secureAsset(path)

    return self:asset(path, true)
end

function _M.__:getScheme(secure)

    if not secure then

        return self._forceSchema or self:getRequest().scheme .. '://'
    end
    
    return secure and 'https://' or 'http://'
end

function _M:forceSchema(schema)

    self._forceSchema = schema .. '://'
end

function _M:route(name, parameters, absolute)

    absolute = lf.needTrue(absolute)
    parameters = parameters or {}

    local route = self.routes:getByName(name)

    if route then
        
        return self:toRoute(route, parameters, absolute)
    end

    lx.throw("invalidArgumentException", fmt("Route [%s] not defined.", name))
end

function _M.__:toRoute(route, parameters, absolute)

    parameters = self:formatParameters(parameters)
    local domain = self:getRouteDomain(route, parameters)
    local root = self:replaceRoot(route, domain, parameters)

    local uri = self:addQueryString(
        self:trimUrl(root, 
            self:replaceRouteParameters(route.uri, parameters)
        ),
        parameters
    )

    if str.rematch(uri, [[\{.*?\\}]]) then
        lx.throw('urlGenerationException', 'missingParameters', route)
    end

    uri = str.strtr(lf.rawurlencode(uri), self.dontEncode)

    return absolute and uri or '/' .. str.ltrim(str.replace(uri, root, ''), '/')
end

function _M:replaceRoot(route, domain, parameters)

    local root = self:getRouteRoot(route, domain)

    return self:replaceRouteParameters(root, parameters)
end

function _M.__:replaceRouteParameters(path, parameters)

    path = self:replaceNamedParameters(path, parameters)

    path = str.rereplace(path, [[\{.*?\}]], function(match)

        return lf.isEmpty(parameters) and not str.endsWith(match[0], '%?}')
            and match[0] or tb.shift(parameters)
    end)
    
    return str.trim(str.rereplace(path, [[\{.*?\?\}]], ''), '/')
end

function _M.__:replaceNamedParameters(path, parameters)
    
    return str.rereplace(path, [[\{(.*?)\??\}]], function(m)
        return parameters[m[1]] and tb.pull(parameters, m[1]) or m[0]
    end)
end

function _M.__:addQueryString(uri, parameters)

    local fragment = lf.parseUrl(uri, 'fragment')
    
    if fragment then
        uri = str.rereplace(uri, '#.*', '')
    end
    uri = uri .. self:getRouteQueryString(parameters)
    
    return (not fragment) and uri or (uri .. "#" .. fragment)
end

function _M.__:formatParameters(parameters)

    return self:replaceRoutableParameters(parameters)
end

function _M.__:replaceRoutableParameters(parameters)

    parameters = parameters or {}
    parameters = lf.isTbl(parameters) and parameters or {parameters}

    for key, parameter in pairs(parameters) do
        if lf.isObj(parameter) and parameter:__is('urlRoutable') then
            parameters[key] = parameter:getRouteKey()
        end
    end
    
    return parameters
end

function _M.__:getRouteQueryString(parameters)

    if not next(parameters) then
        
        return ''
    end
    local keyed = self:getStringParameters(parameters)
    local query = lf.httpBuildQuery(keyed)

    if #keyed < #parameters then
        query = query .. '&' .. str.join(self:getNumericParameters(parameters), '&')
    end

    return '?' .. str.trim(query, '&')
end

function _M.__:getStringParameters(parameters)

    return tb.filter(parameters, lf.isStr, 1)
end

function _M.__:getNumericParameters(parameters)

    return tb.filter(parameters, lf.isNum, 1)
end

function _M.__:getRouteDomain(route, parameters)

    return route:domain() and self:formatDomain(route, parameters) or nil
end

function _M.__:formatDomain(route, parameters)

    return self:addPortToDomain(self:getDomainAndScheme(route))
end

function _M.__:getDomainAndScheme(route)

    return self:getRouteScheme(route) .. route:domain()
end

function _M.__:addPortToDomain(domain)

    local secure = self:getRequest().isSecure
    local port = tonumber(self:getRequest().port)
    if secure and port == 443 or not secure and port == 80 then
        
        return domain
    end
    
    return domain .. ':' .. port
end

function _M.__:getRouteRoot(route, domain)

    return self:getRootUrl(self:getRouteScheme(route), domain)
end

function _M.__:getRouteScheme(route)

    if route:httpOnly() then
        
        return self:getScheme(false)
    elseif route:httpsOnly() then
        
        return self:getScheme(true)
    end
    
    return self:getScheme(nil)
end

function _M:action(action, parameters, absolute)

    absolute = lf.needTrue(absolute)
    parameters = parameters or {}
    if self.rootNamespace and not (str.strpos(action, '.') == 1) then
        action = self.rootNamespace .. '.' .. action
    end
    local route = self.routes:getByAction(action)
    if route then
        
        return self:toRoute(route, parameters, absolute)
    end

    lx.throw("invalidArgumentException", "action " .. action .. " not defined.")
end

function _M.__:getRootUrl(scheme, root)

    if not root then
        root = self.forcedRoot or self:getRequest().root
    end
    local start = str.startsWith(root, 'http://') and 'http://' or 'https://'
    
    return str.rereplace(root, '~' .. start .. '~', scheme)
end

function _M:forceRootUrl(root)

    self.forcedRoot = str.rtrim(root, '/')
end

function _M:isValidUrl(path)

    if str.startsWith(path, {'#', '//', 'mailto:', 'tel:', 'http://', 'https://'}) then
        
        return true
    end
    
end

function _M.__:trimUrl(root, path, tail)

    tail = tail or ''

    return str.trim(root .. '/' .. str.trim(path .. '/' .. tail, '/'), '/')
end

function _M:getRequest()

    return app:get('request')
end

function _M:setRoutes(routes)

    self.routes = routes
    
    return self
end

function _M.__:getPreviousUrlFromSession()

    local session = self:getSession()

    return session and session:previousUrl()
end

function _M.__:getSession()

    return app:get('session')
end

function _M:setRootControllerNamespace(rootNamespace)

    self.rootNamespace = rootNamespace
    
    return self
end

return _M

