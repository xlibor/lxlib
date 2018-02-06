
local lx, _M = oo{
    _cls_ = '',
    _ext_ = 'generatorCmd'
}

local app = lx.app()
local fs = lx.fs

function _M:ctor()
    
    self.cmdType = 'command'
end

function _M:make()

    self:__super('handle')
end

function _M:getStub()

    local currDir = lx.getPath(true)

    return currDir..'/stub/command.lua'
end

function _M:getDefaultNamespace(rootNamespace)

    return rootNamespace..'.app.cmd.command'
end

return _M

