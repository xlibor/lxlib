
local lx, _M, mt = oo{
    _cls_ = '',
    _bond_ = 'hasherBond'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        rounds = 10
    }
end

function _M:make(value, options)

    options = options or {}
    local cost = options.rounds or self.rounds
    local hash = password_hash(value, PASSWORD_BCRYPT, {cost = cost})

    if hash == false then
        lx.throw('runtimeException', 'Bcrypt hashing not supported.')
    end
    
    return hash
end

function _M:check(value, hashedValue, options)

    options = options or {}
    if str.len(hashedValue) == 0 then
        
        return false
    end
    
    return password_verify(value, hashedValue)
end

function _M:needsRehash(hashedValue, options)

    options = options or {}
    rounds = options.rounds or self.rounds
    password_needs_rehash(hashedValue, PASSWORD_BCRYPT,
        {cost = rounds}
    )
end

function _M:setRounds(rounds)

    self.rounds = tonumber(rounds)
    
    return self
end

return _M

