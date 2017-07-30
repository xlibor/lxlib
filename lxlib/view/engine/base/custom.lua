
local _M = {
    _cls_ = ''
}

local mt = { __index = _M }

local lx = require('lxlib')
local app, lf, tb, str = lx.kit()

function _M:new()
    
    local this = {
        nts = {},
        parsers = {},
        compilers = {},
        filters = {},
        funcs = {},
        customs = {}
    }

    setmetatable(this, mt)

    return this
end

function _M:addNodeType(ntName)

    tapd(self.nts, ntName)
end

_M.addNt = _M.addNodeType

function _M:addParser(cmd, parser)
 
    self.parsers[cmd] = parser

end

_M.parse = _M.addParser

function _M:addCompiler(cmd, compiler)

    self.compilers[cmd] = compiler

end

_M.compile = _M.addCompiler

function _M:addFilter(filter, callback)

    self.filters[filter] = callback
end

_M.filter = _M.addFilter

function _M:addFunc(name, callback)

    self.funcs[name] = callback
end

_M.func = _M.addFilter

function _M:addCustom(cmd, callback)

    self.customs[cmd] = callback
end

_M.add = _M.addCustom

return _M

