
local lx, bonds = oos{}

local __ = {
    _cls_ = ''
}

function __:count() end

bonds.countable = __

------------------------------------------------

local __ = {
    _cls_ = ''
}

function __:toJson() end

bonds.jsonable = __

------------------------------------------------

local __ = {
    _cls_ = ''
}

function __:get(key, default) end

function __:set(key, value) end

function __:count() end

function __:has(key) end

function __:remove(key) end

bonds.colable = __

------------------------------------------------

local __ = {
    _cls_ = ''
}

function __:toStr() end

bonds.strable = __

------------------------------------------------

local __ = {
    _cls_ = ''
}

function __:toHtml() end

bonds.htmlable = __

------------------------------------------------

local __ = {
    _cls_ = ''
}

function __:render() end

bonds.renderable = __

------------------------------------------------

local __ = {
    _cls_ = ''
}

function __:store() end

function __:restore(data) end

bonds.restorable = __

------------------------------------------------

local __ = {
    _cls_ = ''
}

function __:clone() end

bonds.cloneable = __

------------------------------------------------

local __ = {
    _cls_ = ''
}

function __:call() end

bonds.callable = __

------------------------------------------------

local __ = {
    _cls_ = ''
}

function __:toArr() end

bonds.arrable = __

------------------------------------------------

local __ = {
    _cls_ = ''
}

function __:over() end

bonds.overable = __

------------------------------------------------

local __ = {
    _cls_ = ''
}

function __:toEach() end

bonds.eachable = __

------------------------------------------------

local __ = {
    _cls_ = ''
}

function __:dive() end

bonds.divable = __

------------------------------------------------

local __ = {
    _cls_ = ''
}

function __:toFix(nick) end

bonds.fixable = __

------------------------------------------------

local __ = {
    _cls_ = ''
}

function __:pack() end

function __:unpack(value) end

bonds.packable = __

return bonds


