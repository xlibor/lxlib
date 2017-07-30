
local _M = {
    _cls_    = ''    
}

local mt = {__index = _M}

local lx = require('lxlib')
local app, lf, tb, Str = lx.kit()

function _M:new()

    local this = {
        data = {}
    }

    setmetatable(this, mt)

    return this
end

function _M:getChunk(key)

    local tpl = self:getTpl(key)

    return tpl.chunk
end

function _M:getCode(key)

    local tpl = self:getTpl(key)

    return tpl.code
end

function _M:getResult(key)

    local tpl = self:getTpl(key)

    return tpl.result
end

function _M:getTpl(key)

    local tpl = self.data[key]
    if not tpl then
        tpl = {}
        self.data[key] = tpl
    end

    return tpl
end

function _M:getObj(key)

    local tpl = self:getTpl(key)

    return tpl.obj
end

function _M:setObj(key, obj)

    local tpl = self:getTpl(key)
    tpl.obj = obj
end

function _M:setChunk(key, chunk)

    local tpl = self:getTpl(key)
    tpl.chunk = chunk
end

function _M:setCode(key, code)

    local tpl = self:getTpl(key)
    tpl.code = code
end

function _M:setResult(key, result)

    local tpl = self:getTpl(key)
    tpl.result = result
end
 
function _M:clear()

    self.data = {}
end

return _M

