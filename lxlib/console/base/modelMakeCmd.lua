
local lx, _M = oo{
    _cls_ = '',
    _ext_ = 'generatorCmd'
}

local app, lf, tb, str = lx.kit()
local fs = lx.fs

function _M:ctor()
    
    self.cmdType = 'model'
end

function _M:make()

    local modelName = self:arg(1)
 
    self:__super('handle')
end

function _M:getStub()

    local currDir = lx.getPath(true)

    return currDir..'/stub/model.lua'

end

function _M:getDefaultNamespace(rootNamespace)

    return rootNamespace..'.app.model'
end

function _M:replaceClass(stub, name)

    local stub = self:__super('replaceClass', stub, name)
    stub = str.replace(stub, 'tableName', name)

    return stub
end

return _M

