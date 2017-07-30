
local lx, _M = oo{ 
    _cls_ = '',
    _ext_ = 'generatorCmd'
}

local app, lf, tb, str = lx.kit()
local fs = lx.fs

function _M:ctor()
    
    self.cmdType = 'seeder'
end

function _M:make()

    self:__super('handle')
end

function _M:getStub()

    local currDir = lx.getPath(true)

    return currDir..'/stub/seeder.lua'

end

function _M:getDefaultNamespace(rootNamespace)

    return rootNamespace..'.db.seed'
end


return _M

