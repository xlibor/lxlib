
local lx, _M, mt = oo{
    _cls_    = '',

}

local app, lf, tb, str, new = lx.kit()

local restyHttp = require('resty.http')

function _M:new(config)

    local this = {
        config = config,
        baseClient = nil,
        whenFail = nil,
        maxFailCount = 1,
        timeout = nil,
        timeouts = nil,
        keepalive = nil,
        poolSize = nil,
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

    options = self:applyOptions(options)

    local headers = options.headers or {}
    local body = options.body
    local version = options.version or '1.1'
    local query = options.query

    uri = self:buildUri(uri, options)

    local request = new('net.http.request', method, uri, headers, body, version, query)
    
    options.headers = nil; options.body = nil; options.version = nil

    return self:transfer(request, options)
end

function _M:getBase()

    local httpc = self.baseClient
    if not httpc then
        httpc = restyHttp.new()
        self.baseClient = httpc
    end

    return httpc
end

function _M.__:transfer(request, options)

    local httpc = self:getBase()

    local res, err
    local failCount = 0

    while true do
        res, err = httpc:request_uri(request.uri, {
            method = request.method,
            body = request.body,
            query = request.query,
            headers = request.headers,
            ssl_verify = false,
        })

        if not res then
            err = tostring(err) or 'unknown err'
            failCount = failCount + 1
            if failCount >= self.maxFailCount then
                break
            end
            if self.whenFail then
                if self.whenFail(err, request) then
                    break
                end
            end
        else
            break
        end
    end

    if not res then
        return nil, err
    end

    local response = new('net.http.response', res.status, res.headers, res.body, res.version, res.reason)

    if self.keepalive then
        self:setKeepalive(self.keepalive, self.poolSize)
    end

    return response
end

function _M.__:applyOptions(options)

    options.headers = options.headers or {}
    local body = options.body
    if type(body) == 'table' then
        body = lf.httpBuildQuery(body)
        options.body = body
    end

    if body then
        if not options.headers["Content-Type"] then
            options.headers["Content-Type"] = "application/x-www-form-urlencoded"
        end
    end
    
    local query = options.query
    if type(query) == 'table' then
        query = lf.httpBuildQuery(query)
        options.query = query
    end

    return options
end

function _M.__:buildUri(uri, options)

    return uri
end

function _M.__:prepareDefaults(options)

    local defaults = self.config
 
    local result = tb.mergeDict(options, defaults)

    return result
end

function _M:setKeepalive(second, poolSize)

    second = second or 60
    local ms = second * 1000
    poolSize = poolSize or 10

    return self:getBase():set_keepalive(ms, poolSize)
end

function _M:close()

    self:getBase():close()
end

function _M:setTimeouts(connectTimeout, sendTimeout, readTimeout)
    
    self:getBase():set_timeouts(connectTimeout, sendTimeout, readTimeout)
end

return _M

