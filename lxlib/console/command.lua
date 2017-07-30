
local _M = { 
    _cls_ = '',
    _ext_ = 'baseCmd'
}

local mt = { __index = _M }

local lx = require('lxlib')
local app = lx.app()

function _M:new(input, output)

    local this = {
        input = input,
        output = output
    }

    setmetatable(this, mt)

    return this
end

function _M:ctor()

    self.args = self.input.args
end

function _M:arg(key, default)

    return self.input:getArg(key, default)
end

function _M:setArg(key, value)

    self.input:setArg(key, value)
end

function _M:call(cmd, args)

    local kernel = app:make('console.kernel')
    return kernel:run(cmd, args)
end

function _M:line(msg, style)

    self.output:line(msg, style)
end

function _M:error(msg)

    self:line(msg, 'error')
end

function _M:text(msg)
    
    self:line(msg, 'text')
end

function _M:comment(msg)

    self:line(msg, 'comment')
end

function _M:info(msg)
    
    self:line(msg, 'info')
end

function _M:warn(msg)

    self:line(msg, 'warn')
end

function _M:cheer(msg)

    self:line(msg, 'cheer')
end

function _M:write(...)

    self.output:write({...})
end

function _M:print(s)

    self.output:write(s, false)
end

function _M:ask(question, default)

    return self.output:ask(question, default)
end

function _M:confirm(question, default)

    return self.output:confirm(question, default)
end

return _M

