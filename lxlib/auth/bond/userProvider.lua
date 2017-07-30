
local __ = {
    _cls_ = ''
}

function __:retrieveById(identifier) end

function __:retrieveByToken(identifier, token) end

function __:updateRememberToken(user, token) end

function __:retrieveByCredentials(credentials) end

function __:validateCredentials(user, credentials) end

return __

