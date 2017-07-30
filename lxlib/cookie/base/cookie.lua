
local lx, _M, mt = oo{
    _cls_ = ''
}

local lf = lx.f

function _M:new(name, value, expire, path, domain, secure, httpOnly)

    local this = {
        name = name,
        value = value,
        expire = expire or 0,
        path = path or '/',
        domain = domain,
        secure = secure or false,
        httpOnly = lf.needTrue(httpOnly)
    }

    oo(this, mt)
    this:init()

    return this
end

function _M:init()

end

function _M:toStr()

end

function _M:toArr()

    return {
        name = self.name,  value = self.value,
        expire = self.expire,  path = self.path,
        domain = self.domain, secure = self.secure,
        httpOnly = self.httpOnly
    }
end

function _M:from()

end

function _M:isCleared()

    if self.expire < lf.timestamp() then
        return true
    end
end

return _M

