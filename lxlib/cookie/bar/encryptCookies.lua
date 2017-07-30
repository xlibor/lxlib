
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        except = {}
    }
    
    return oo(this, mt)
end

function _M:ctor()

    self.encrypter = encrypter
end

function _M:disableFor(cookieName)

    self.except = tb.merge(self.except, lf.needList(cookieName))
end

function _M:handle(request, next)

    return self:encrypt(next(self:decrypt(request)))
end

function _M.__:decrypt(request)

    for key, c in pairs(request.cookies) do
        if self:isDisabled(key) then
            continue
        end
        try(function()
            request.cookies:set(key, self:decryptCookie(c))
        end)
        :catch(function(DecryptException e) 
            request.cookies:set(key, nil)
        end)
        :run()
    end
    
    return request
end

function _M.__:decryptCookie(cookie)

    return lf.isTbl(cookie) and self:decryptArray(cookie) or self.encrypter:decrypt(cookie)
end

function _M.__:decryptArray(cookie)

    local decrypted = {}
    for key, value in pairs(cookie) do
        if lf.isStr(value) then
            decrypted[key] = self.encrypter:decrypt(value)
        end
    end
    
    return decrypted
end

function _M.__:encrypt(response)

    for _, cookie in pairs(response.headers:getCookies()) do
        if self:isDisabled(cookie:getName()) then
            continue
        end
        response.headers:setCookie(self:duplicate(cookie, self.encrypter:encrypt(cookie:getValue())))
    end
    
    return response
end

function _M.__:duplicate(c, value)

    return new('cookie' ,c:getName(), value, c:getExpiresTime(), c:getPath(), c:getDomain(), c:isSecure(), c:isHttpOnly())
end

function _M:isDisabled(name)

    return tb.inList(self.except, name)
end

return _M

