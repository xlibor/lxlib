
local __ = {
    _cls_ = ''
}

function __:get(key) end

-- function __:many(keys) end

function __:put(key, value, minutes) end

-- function __:putMany(values, minutes) end

function __:forever(key, value) end

function __:forget(key) end

function __:flush() end

-- function __:getPrefix() end

return __

