
local _M = {
    _cls_ = ''
}

local mt = { __index = _M }

local colBase = require('lxlib.base.col')
local tb = require('lxlib.base.arr')

function _M:new(pubEnv, appEnv)

    local curEnv
    if appEnv then
        curEnv = tb.mix(pubEnv, appEnv)
    else
        curEnv = pubEnv
    end

    local col = colBase:new()
    col:useDict()
    col:init(curEnv)
    col:itemable():dotable()
 
    return col
end

return _M

