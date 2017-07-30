
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
    }

    return oo(this, mt)
end

function _M:handle(e, ...)

    local event = e.name

    local handler = self[event]
    if handler then
        handler(self, ...)
    end
end

function _M:attempting(credentials, remember)

end

function _M:authenticated(user)

end

function _M:failed(user, credentials)

end

function _M:lockout(request)

end

function _M:login(user, remember)

end

function _M:logout(user)

end

function _M:reged(user)

end

return _M

