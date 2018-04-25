
local lx, _M, mt = oo{
    _cls_     = '',
    _bond_    = 'sessionHandlerBond'
}

local app, lf, tb, str = lx.kit()

function _M:new(connection, table)

    local this = {
        connection = connection,
        table = table,
        exists = false
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

    local q, f, w = self:getQuery()
    local session = q:find(sessionId)

    if session then
        local payload = session.payload
        if payload then
            self.exists = true

            return lf.base64De(payload)
        end
    end
end

function _M:write(sessionId, data)

    local payload = self:getDefaultPayload(data)
    if not self.exists then
        self:read(sessionId)
    end

    local q = self:getQuery()
    if self.exists then
        q:set(payload)
        q:where{id = sessionId}:update()
    else
        payload.id = sessionId
        q:set(payload)
        q:insert()
    end
 
    self.exists = true
end

function _M:destroy(sessionId)
    
    local q = self:getQuery()

    q:where{id = sessionId}:delete()
end

function _M:gc(lifetime)

    local q, f, w = self:getQuery()
    q:where(f.last_activity, '<=', lf.time() - lifetime):delete()
end

function _M:setExists(value)

    self.exists = value

    return self
end

function _M.__:getQuery()

    local db = app:get('db')
    local q, f, w = self.connection:table(self.table)

    return q, f, w
end

function _M.__:getDefaultPayload(data)

    local payload = {
        payload = lf.base64En(data),
        last_activity = lf.time()
    }

    local req = app:get('request')
    if req then
        payload.ip_address = req.ip
    end
    local auth = app:get('auth')
    if auth then
        local userId = auth:guard():getId()
        if userId then
            payload.user_id = userId
        end
    end
    
    return payload
end

return _M

