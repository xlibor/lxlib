
local lx, _M, mt = oo{
    _cls_   = '',
    _bond_  = 'tokenRepositoryInterface'
}

local app, lf, tb, str = lx.kit()

function _M:new(connection, hasher, table, hashKey, expires)

    expires = expires or 60

    local this = {
        connection = connection,
        hasher = hasher,
        table = table,
        hashKey = hashKey,
        expires = expires * 60
    }
end

function _M:create(user)

    local email = user:getEmailForPasswordReset()
    self:deleteExisting(user)
    
    local token = self:createNewToken()
    self:getTable():insert(self:getPayload(email, token))
    
    return token
end

function _M.__:deleteExisting(user)

    return self:getTable():where('email', user:getEmailForPasswordReset()):delete()
end

function _M.__:getPayload(email, token)

    return {email = email, token = self.hasher:make(token), created_at = new('carbon')}
end

function _M:exists(user, token)

    local record = self:getTable():where('email', user:getEmailForPasswordReset()):first()
    
    return record and not self:tokenExpired(record['created_at']) and self.hasher:check(token, record['token'])
end

function _M.__:tokenExpired(createdAt)

    return Carbon.parse(createdAt):addSeconds(self.expires):isPast()
end

function _M:delete(user)

    self:deleteExisting(user)
end

function _M:deleteExpired()

    local expiredAt = Carbon.now():subSeconds(self.expires)
    self:getTable():where('created_at', '<', expiredAt):delete()
end

function _M:createNewToken()

    return hash_hmac('sha256', str.random(40), self.hashKey)
end

function _M:getConnection()

    return self.connection
end

function _M.__:getTable()

    return self.connection:table(self.table)
end

function _M:getHasher()

    return self.hasher
end

return _M

