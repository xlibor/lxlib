
local lx, _M, mt = {
    _cls_ = ''
}

require('lxlib.resty.http')

function _M:new(url, method, args, timeout, scheme)

    local this = {
        url = url or '',
        method = method or 'GET',
        args = args or '',
        timeout = timeout or 8000,
        scheme = scheme or 'http'
--        success
--        reqHeaders = {},
--        respHeaders = {},
--        reqBody,respBody,
--        ok,
--        status
    }
    
    oo(this, mt)
    
    return this
end

function _M:send()

    local hc = resty.http:new()
    local url = self.url
    local method = self.method
    local reqHeaders = self.reqHeaders or {}
    local contentType = reqHeaders['Content-Type']
    local reqBody = self.args
    local scheme = self.scheme or 'http'

    if method == 'POST' then
        if not contentType then
            reqHeaders['Content-Type'] = 'application/x-www-form-urlencoded'
        end
--        reqBody = ngx.escape_uri(reqBody)
 
    else
        reqHeaders = nil
        url = url..'?'..reqBody
    end
    
    local ok, code, respHeaders, status, respBody  = hc:request{
        url = url,
        method = method,
        headers = reqHeaders,
        timeout = self.timeout,
        body = reqBody,
        scheme = scheme
    }

    local success = false
    self.ok = ok; self.code = code; self.respHeaders = respHeaders
    respBody = respBody or ''
    self.status = status; self.respBody = respBody
    if ok and code == 200 then 
        success = true 
    else
        respBody = code
    end
    self.success = success
    
    return success, respBody
end

return _M

