
local lx, _M = oo{ 
    _cls_ = '',
    _ext_ = 'command'
}

local app, lf, tb, str = lx.kit()
local fs = lx.fs

function _M:ctor()

end

function _M:handle()

    local rawName = self:getNameInput()
    if not rawName then
        self:warn('rawName invalid')
        return
    end

    local name = self:parseName(rawName)
    local path = self:getPath(name)

    if self:alreadyExists(rawName) then
        self:warn(rawName .. ' already exists')
        return
    end

    self:makeDirectory(path)
    local code = self:buildClass(rawName)

    fs.put(path, code)

    local cmdType = self.cmdType
    self:info('created '..cmdType..' successfully in '..path)
end

function _M.__:alreadyExists(rawName)

    local name = self:parseName(rawName)
    local path = self:getPath(name)

    return fs.exists(path)
end

function _M.__:getPath(name)

    local rootPath = self.rootPath
    local path = str.replace(name, '%.', '/')
    path = rootPath .. '/' .. path .. '.lua'

    return path
end

function _M.__:parseName(name)

    local rootNamespace = self.appName
    if str.startsWith(name, rootNamespace) then
        return name
    end

    if str.has(name, '/') then
        name = str.replace(name, '/', '')
    end

    local t = str.trim(rootNamespace, '.')
    
    return self:parseName(self:getDefaultNamespace(t)..'.'..name)
end

function _M.__:getDefaultNamespace(rootNamespace)

    return rootNamespace
end

function _M.__:makeDirectory(path)

    local dir = fs.dirName(path)

    if not fs.isDir(dir) then

        fs.makeDir(dir)
    end
end

function _M.__:buildClass(name)

    local stubPath = self:getStub()
    if not fs.exists(stubPath) then
        error('stubPath not exists')
    end

    local stub = fs.get(stubPath)
    stub = self:replaceClass(stub, name)

    return stub
end

function _M.__:replaceClass(stub, name)

    local class = name
    stub = str.replace(stub, 'DummyClass', class)

    return stub
end

function _M.__:getNameInput()

    return self:arg(1)
end

return _M

