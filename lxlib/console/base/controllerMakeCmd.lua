
local lx, _M = oo{
    _cls_ = '',
    _ext_ = 'generatorCmd'
}

local app = lx.app()
local fs = lx.fs

function _M:ctor()
    
    self.cmdType = 'controller'
end

function _M:make()

    local ctlerName = self:arg(1)

    self:__super('handle')
end

function _M:getStub()

    local currDir = lx.getPath(true)

    return currDir..'/stub/controller.lua'

end

function _M:getDefaultNamespace(rootNamespace)

    return rootNamespace..'.app.http.ctler'
end

return _M

