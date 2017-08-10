
local lx, _M, mt = oo{
    _cls_ = ''
}

local app = lx.app()

local parser = require('lxlib.console.parser')

function _M:new()

    local this = {
    }

    oo(this, mt)

    return this
end

function _M:ctor(args, cmd)

    local info = parser.parse(args, cmd)
    self.uri = info.uri
    self.args = info.cmdArgs
    self.mainCmd = info.mainCmd
    self.subCmd = info.subCmd
end

function _M:getArg(key, default)

    local args = self.args
    local value = args[key] or default

    return value
end

function _M:setArg(key, value)

    local args = self.args
    args[key] = value
end

return _M

