
local __ = {
    _cls_ = ''
}

function __:has(ability) end

function __:define(ability, callback) end

function __:policy(class, policy) end

function __:before(callback) end

function __:after(callback) end

function __:allows(ability, arguments) end

function __:denies(ability, arguments) end

function __:check(ability, arguments) end

function __:authorize(ability, arguments) end

function __:getPolicyFor(class) end

function __:forUser(user) end

return __

