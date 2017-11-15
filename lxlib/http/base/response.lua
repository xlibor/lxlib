
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        statusText = '',
        version = '1.1',
        charset = 'utf-8'
    }

    oo(this, mt)

    return this
end

function _M:ctor(content, status, headers)

    self.content = content or false
    self:setStatusCode(status or 200)

    self.headers = app:make('lxlib.http.base.responseHeader', headers)
end

function _M:create(content, status, headers)

    return self:__new(content, status, headers)
end

function _M:send()
    
    self:sendStatus()
    self:sendHeaders()
    self:sendContent()

    return self
end

function _M:sendStatus()
    
    ngx.status = self.statusCode
end

function _M:sendHeaders()
    
    local headers = self.headers

    local cookies =  headers:getCookies()
    if #cookies > 0 then
        local ckj = app:get('cookie')
        for _, v in ipairs(cookies) do

            ckj:set(v:toArr())
        end
    end

    for k, v in headers:kv() do

        ngx.header[k] = v
    end

    return self
end

function _M:sendContent()

    local content = self.content
    if content then 
        ngx.print(content)
    end

    return self
end

function _M:prepare(request)

    if request.method == 'head' then
        self:setContent('')
    end
end

function _M:tryToStr(content)

    local typ = type(content)
    if typ == 'table' then
        if content.__cls then 
            if content:__is 'strable' then
                content = content:toStr()
            end
        end
    else
        content = tostring(content)
    end

    return content
end

function _M:setContent(content)

    self.content = self:tryToStr(content)
end

function _M:getContent()

    return self.content
end

function _M:setStatusCode(code)

    self.statusCode = tonumber(code) or 0

    if self:isInvalid() then
        error('http status code in not valid')
    end
end

function _M:getStatusCode()

    return self.statusCode
end

function _M:isInvalid()

    local code = self.statusCode

    return code < 100 or code >= 600
end

function _M:isInformational()

    local code = self.statusCode

    return code >= 100 and code < 200
end
 
function _M:isSuccessful()

    local code = self.statusCode

    return code >= 200 and code < 300
end

function _M:isRedirection()

    local code = self.statusCode

    return code >= 300 and code < 400
end

function _M:isClientError()

    local code = self.statusCode

    return code >= 400 and code < 500
end

function _M:isServerError()

    local code = self.statusCode

    return code >= 500 and code < 600
end

function _M:isOk()

    local code = self.statusCode

    return code == 200
end

function _M:isForbidden()

    local code = self.statusCode

    return code == 403
end

function _M:isNotFound()

    local code = self.statusCode

    return code == 404
end

function _M:isRedirect(location)

    local code = self.statusCode

    local isCodeIn = lf.isIn(code, 201, 301, 302, 303, 307, 308)
    if not isCodeIn then return false end

    if location then
        return location == self.headers:get('Location')
    else 
        return true
    end
end

function _M:isEmpty()

    local code = self.statusCode

    return code == 204 or code == 304
end

return _M

