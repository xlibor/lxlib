
local _M = {
    _cls_ = ''
}
local mt = { __index = _M }



local lx = require('lxlib')
local app, lf, tb, str = lx.kit()

function _M:new()
     
    local this = {
     }
    setmetatable(this, mt)
 
    return this
end

function _M:raise(excpType, ...)
     
    local typ = type(excpType)
    local e
    if typ == 'table' then 
        e = excpType
        excpType = e.__cls
    else
        e = app:make(excpType, ...)
    end
 
    local ctx = ngx.ctx
    ctx.tempException = e

    local errStr = "[- @type:" .. excpType .. ' -]'
 
    error(errStr, 2)
end

return _M

