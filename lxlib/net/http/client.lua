
local lx, _M, mt = oo{
    _cls_    = '',

}

local app, lf, tb, str = lx.kit()
local new = lx.new

local restyHttp = require('resty.http')

function _M:new(config)

    local this = {
        config = config
    }

    return oo(this, mt)

end

function _M:ctor()

end

function _M:request(method, uri, options)

    options = options or {}
    uri = uri or ''
    options.sync = false
    options.async = true

    return self:requestAsync(method, uri, options)
end

function _M:get(uri, options)

    return self:request('get', uri, options)
end

function _M:post(uri, options)

    return self:request('post', uri, options)
end

function _M.__:requestAsync(method, uri, options)

    options = options or {}
    uri = uri or ''
    options = self:prepareDefaults(options)

    local headers = options['headers'] or {}
    local body = options['body']
    local version = options['version'] or '1.1'

    uri = self:buildUri(uri, options)

    local request = new('net.http.request', method, uri, headers, body, version)
    
    options.headers = nil; options.body = nil; options.version = nil

    return self:transfer(request, options)

end

function _M.__:transfer(request, options)

    local httpc = restyHttp.new()
    local res, err = httpc:request_uri(request.uri, {
        method = request.method,
        body = request.body,
        headers = {
            ["Content-Type"] = "application/x-www-form-urlencoded",
        },
        ssl_verify = false,
    })

    if not res then
        error("failed to request: " .. tostring(err))
        return
    end

    local response = new('net.http.response', res.status, res.headers, res.body, res.version, res.reason)

    return response
end

function _M.__:buildUri(uri, options)

    return uri
end

function _M.__:prepareDefaults(options)

    local defaults = self.config
 
    local result = tb.mergeDict(options, defaults)

    return result
end

return _M

