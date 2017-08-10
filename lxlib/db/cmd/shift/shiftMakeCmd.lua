
local lx, _M = oo{
    _cls_ = '',
    _ext_ = 'generatorCmd',
    sign = {
        make = {
            table  = {short = 't', opt = true},
            create = {short = 'c', opt = true, value = true}
        }
    }
}

local app, lf, tb, str = lx.kit()
local fs = lx.fs

function _M:ctor()
    
    self.cmdType = 'shift'
end

function _M:make()

    self:__super('handle')
end

function _M.__:getPath(name)

    local rootPath = self.rootPath
    name = str.replace(name, '%.', '/')
    local path, name = fs.split(name)
    name = self:getDatePrefix()..'_'..name
    path = rootPath..'/'..path..'/'..name..'.lua'

    return path
end

function _M.__:getDatePrefix()

    return lf.datetime('%Y_%m_%d_%H%M%S')
end

function _M.__:getStub()

    local currDir = lx.getPath(true)

    local table = self:arg('table')
    local create = self:arg('create')
    local stub = 'shiftBlank'
    if table then
        stub = create and 'shiftCreate' or 'shiftUpdate'
    end

    return currDir..'/stub/'..stub..'.lua'
end

function _M.__:getDefaultNamespace(rootNamespace)

    return rootNamespace..'.db.shift'
end

function _M.__:replaceClass(stub, name)

    local table = self:arg('table')

    local stub = self:__super('replaceClass', stub, name)
    if table then
        stub = str.replace(stub, 'DummyTable', table)
    end

    return stub
end

return _M

