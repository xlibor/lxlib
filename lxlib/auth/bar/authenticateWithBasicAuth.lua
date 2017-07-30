
local lx, _M, mt = oo{
    _cls_ = ''
}

function _M:new(auth)

    local this = {
        auth = auth
    }
end

function _M:handle(context, next, guard)

    return self.auth:guard(guard):basic() or next(context)
end

return _M

