
local lx, _M, mt = oo{
    _cls_     = '',
    _bond_    = 'sessionHandlerBond'
}

local app, lf, tb, str = lx.kit()

function _M:new(minutes)

    local this = {
        minutes = minutes,
        request = nil
    }

    return oo(this, mt)
end

function _M:open(savePath, sesssionName)

    return true
end

function _M:close()

    return true
end

function _M:read(sessionId)

    local payload = self.request.cookies:get(sessionId)

    if payload then
        return lf.base64De(payload)
    end
end

function _M:write(sessionId, data)

    local ckj = app:get('cookie')
    data = lf.base64En(data)
    ckj:queue(sessionId, data, self.minutes)
end

function _M:destroy(sessionId)

    local ckj = app:get('cookie')
    ckj:queue(ckj:forget(sessionId))
end

function _M:gc(lifetime)

    return true
end

function _M:setRequest(request)

    self.request = request
end

return _M

