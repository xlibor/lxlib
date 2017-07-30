
local lx, _M, mt = oo{
    _cls_     = '',
    _bond_    = 'sessionHandlerBond'
}

local app, lf, tb, str = lx.kit()

function _M:new(cache, minutes)

    local this = {
        cache = cache,
        minutes = minutes
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

    return self.cache:get(sessionId) or ''
end

function _M:write(sessionId, data)

    self.cache:put(sessionId, data, self.minutes * 60)
end

function _M:destroy(sessionId)

    return self.cache:forget(sessionId)
end

function _M:gc(lifetime)

    return true
end

function _M:getCache()

    return self.cache
end

return _M

