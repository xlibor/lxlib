local __ = {
    _cls_ = '',
    _ext_ = 'authGuardBond'
}

function __:attempt(credentials, remember) end

function __:once(credentials) end

function __:login(user, remember) end

function __:loginUsingId(id, remember) end

function __:onceUsingId(id) end

function __:viaRemember() end

function __:logout() end

return __

