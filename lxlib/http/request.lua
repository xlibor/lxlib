 
local lx, _M, mt = oo{
    _cls_       = '',
    _mix_       = 'baseRequest',
    _static_    = {

    }
}

local app, lf, tb, str, new = lx.kit()
local static

function _M._init_(this)

    static = this.static
end

function _M:new()
    
    local this = {
        _all            = false,
        _posts          = false,
        _actionName     = false,
        _ctlerName      = false,
        _route          = false,
    }

    return oo(this, mt)
end

function _M:ctor(uri, method, args, cookies, files)

    if not uri then
        self:init()
    else
        method = method or 'get'
        local q = lf.parseUrl(uri)

        self.host = q.host or ''
        if not str.find(uri, ':') and not str.startsWith(uri, '/') then
            uri = '/' .. uri
            self.path = uri
            self.host = ''
        else
            self.path = q.path or uri
        end

        self.uri = uri

        self.method = str.lower(method) or 'get'
        args = args or {}
        self.args = lx.col(args)
        self.url = self.uri
        if q.scheme then
            if q.scheme == 'http' then
                self.isSecure = false
            elseif q.scheme == 'https' then
                self.isSecure = true
            end
            self.scheme = q.scheme
        end
    end

    self:initPath()
end

function _M.t__.create(this, uri, method, args, cookies, files)

    local req = new(this, uri, method, args, cookies, files)

    return req
end

function _M:init()

    self.path = ngx.var.uri
    self.method = str.lower(ngx.req.get_method()) or 'get'
    self.uri = ngx.var.uri
    self.url = ngx.var.request_uri
end

function _M.__:initPath()

    local path = str.trim(self.path, '/')
    if path == '' then
        path = '/'
    end

    self.path = path
end

function _M.d__:gets()

    return ngx.req.get_uri_args()
end

function _M.d__:posts()

    if self._posts then
        return self._posts
    end

    if not self.isMultiform then
        ngx.req.read_body()
        self._posts = ngx.req.get_post_args()
    else
        self:getFiles()
        if not self._posts then
            self._posts = {}
        end
    end

    return self._posts
end

function _M.d__:headers()

    local reqHeader = app:make('requestHeader', ngx.req.get_headers())
    return reqHeader
end

function _M.d__:args()

    return lx.col(self.all)
end

function _M.d__:all()

    if self._all then
        return self._all
    end

    local args = self.gets
    for k, v in pairs(self.posts) do
        args[k] = v
    end

    for k, v in pairs(self.allFiles) do
        args[k] = v
    end

    self._all = args

    return args
end

function _M.d__:host()

    return ngx.var.http_host
end
 
function _M.d__:port()

    local host = self.host
    local port = host and host:match(":(%d+)$") or 80

    return port
end

function _M.d__:cookies()

    local cookies = require('lxlib.cookie.base.cookies'):new():all()
    
    return lx.col(cookies)
end

function _M.d__:fullUri()

    return self.root .. self.uri
end

function _M.d__:fullUrl()

    return self.root .. self.url
end

function _M:segment(index, default)

    return tb.get(self.segments, index, default)
end

function _M.d__:segments()

    local path = self.path
    segments = str.split(path, '/')
    segments = tb.values(tb.filter(segments, function(v)
        return not lf.isEmpty(v)
    end))
    
    return segments
end

function _M.d__:isJson()

    return str.has(self:header('content-type', ''), '/json', '+json')
end

function _M.d__:isSecure()

    return false
end

function _M.d__:isGet()

    return self.method == 'get'
end

function _M.d__:isPost()

    return self.method == 'post'
end

function _M.d__:isMultiform()

    return str.has(self:header('content-type', ''), 'multipart')
end

function _M.d__:accepts()

    local accept = self:header('accept', '')

    return str.split(accept, ',')
end

function _M.d__:ip()

    local headers = self.headers
    local ip = headers:getAny('http-client-ip', 'http-x-forwarded-for', 'remote-addr')
    if not ip then
        ip = ngx.var.remote_addr
    end
 
    return ip
end

function _M.d__:baseUrl()

    return self.url
end

function _M.d__:root()

    local ret = self.scheme .. '://' .. self.host
    ret = str.rtrim(ret, '/')

    return ret
end

function _M.d__:scheme()

    local scheme = self.isSecure and 'https' or 'http'
 
    return scheme
end

function _M.d__:user()

    return self:header('lx-auth-user') or false
end

function _M.d__:pwd()

    return self:header('lx-auth-pwd') or false
end

function _M.d__:pjax()

    return self:header('x-pjax') or false
end

function _M.d__:ajax()

    return self:isXmlHttpRequest()
end

function _M:isXmlHttpRequest()

    local xrw = self:header('x-requested-with')
    if xrw and xrw == 'XMLHttpRequest' then
        return true
    end

    return false
end

function _M:input(key, default)

    local args = self.args

    if not key then
        return self.all
    end
    
    return args:get(key, default)
end

_M.get = _M.input

function _M:pairs(...)

    local args = self.args
    return args:pairs(...)
end

function _M:header(key, default)

    local headers = self.headers

    return headers:get(key, default)
end

function _M:has(...)

    local args = lf.needArgs(...)
    local all = self.all

    local t, vt
    for _, key in ipairs(args) do
        t = all[key]
        if not t then
            return false
        else
            vt = type(t)
            if vt == 'boolean' then
                return false
            end
            t = tostring(t)
            if str.len(t) == 0 then
                return false
            end
        end
    end

    return true
end

function _M:exist(...)
 
    local args = self.args
    if args:hasAll(...) then 
        return true
    else
        return false
    end
end

_M.exists = _M.exist

function _M:only(...)

    local args = self.args
    return args:only(...)
end

function _M:except(...)

    local args = self.args

    return args:except(...)
end

function _M:cookie(name)

    local cks = self.cookies

    return cks:get(name)
end

function _M:hasCookie(key)

    return self:cookie(key) and true or false
end

function _M:is(...)

    local args = lf.needArgs(...)
    local path = self.path
    for _, pattern in ipairs(args) do
        if str.is(path, pattern) then
            return true
        end
    end

    return false
end

function _M:fullUrlIs(...)

    local args = lf.needArgs(...)
    local path = self.fullUrl
    for _, pattern in ipairs(args) do
        if str.is(path, pattern) then
            return true
        end
    end

    return false
end

function _M:getPathInfo()

    return self.path
end

function _M.d__:expectsJson()

    return self.ajax or self.pjax or self.wantsJson
end

function _M.d__:wantsJson()

    local accepts = self.accepts
    local firstAccept = accepts[1]

    if firstAccept then
        return str.has(firstAccept, '/json', '+json') and true or false
    else
        return false
    end
end

function _M:setSession(session)

    self._session = session
end

function _M.d__:session()

    local session = self._session

    if not session then
        error('not set session')
    end

    return session
end

function _M.d__:action()

    return self._actionName
end

function _M.d__:ctler()

    return self._ctlerName
end

function _M:old(key, default)

    local session = self.session

    return session:getOldInput(key, default)
end

function _M:file(key, default)

    return tb.get(self.allFiles, key, default)
end

function _M:hasFile(key)

    return self:file(key) and true or false
end

function _M:getFiles()

    return self.allFiles
end

function _M.d__:allFiles()

    local files = self:convertUploadedFiles() or {}

    return files
end

function _M.__:convertUploadedFiles()

    if self.isMultiform then
        local fh = app:make('formHandler', self)
        local ok, msg, err = fh:handle()

        if ok then
            self._posts = fh.params or {}
            self.posts = nil
            self._all = false
            self.all = nil
            self.args = nil

            return fh.files
        else
            error('get files fail:' .. msg .. ',' .. err)
        end
    end
end

function _M:routeIs(name)

    local route = self:getRoute()

    if route then
        return route:named(name)
    end
end

function _M:route(key)

    local route = self:getRoute()
    if route then
        if not key then
            return route
        end

        return route:param(key)
    end
end

_M.param = _M.route

function _M:getRoute()

    return self._route
end

function _M:setRoute(route)

    self._route = route
end

function _M:setArg(key, value)

    self.args:set(key, value)

    return self
end

function _M:_get_(key)

    return self.args:get(key) or self:param(key)
end

return _M

