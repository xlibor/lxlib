
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()
local fs, json = lx.fs, lx.json

function _M:new(command)

    local this = {
        cmd = command
    }

    return oo(this, mt)
end

function _M:ctor()

end

function _M:install()

    self:initPaths()

    if not self:preCheckup() then return end

    local opmRequires = self:parseDependancy()

    if #opmRequires > 0 then
        self:installOpm(opmRequires)
    end

    self:installRocks()

    self:buildAutoloadFile()
end

function _M:preCheckup()

    if not fs.exists(self.carrierJsonPath) then
        self:error('carrier.json not exists')
        return
    end

    return true
end

function _M.__:installOpm(requires)

    local repo, version, cmd
    for _, each in pairs(requires) do
        repo, version = each[1], each[2]
        cmd = 'opm --install-dir=vendor/lxcarrier/opm-tree get "'
            .. repo ..  version .. '"'
        echo(cmd)
        exec(cmd)
    end

    fs.copy(self.opmLuaSharePath .. '/*', self.vendorPath, 'rf')

    local restyPath = self.vendorPath .. '/resty'
    if fs.exists(restyPath) then
        local files = fs.files(restyPath, 'n', function(file)
            local name, ext = file:sub(1, -5), file:sub(-3)

            if ext == 'lua' then
                return name
            end
        end) or {}

        local dirs = fs.dirs(restyPath, 'n') or {}

        local prefixes = tb.merge(files, dirs)
        local namespaces = {}
        if #prefixes > 0 then
            for _, prefix in ipairs(prefixes) do
                prefix = 'resty.' .. prefix
                namespaces[prefix] = 'vendor .. "' .. prefix .. '"'
            end
            self.opmNamespaces = namespaces
        end
    end
end

function _M.__:installRocks()

    local cmd = 'luarocks install --tree=vendor/lxcarrier/luarocks-tree --only-deps vendor/lxcarrier/app-v1-1.rockspec'
    exec(cmd)

    fs.delete(self.rockspecPath)

    self:checkSys64()

    if not fs.exists(self.rocksManifest) then
        return self:warn('rocks dependancy install failed!')
    end

    local manifest = fs.get(self.rocksManifest)

    local dependInfo = lf.dostr(manifest)
    local repositories = repository
    
    self:buildRepo(repositories)

end

function _M:checkSys64()

    local rocksTreePath = self.rocksTreePath
    if not fs.exists(rocksTreePath .. '/lib') then
        if fs.exists(rocksTreePath .. '/lib64') then
            self.rocksManifest = rocksTreePath .. '/lib64/luarocks/rocks/manifest'
            self.rocksLuaLibPath = rocksTreePath .. '/lib64/lua/5.1'
        end
    end
end

function _M:reset()

    self:initPaths()

    local ret = self:confirm(
        'Do you want to remove [' .. self.vendorPath .. ']?',
        false
    )

    if ret then
        fs.deleteDir(self.vendorPath)
        self:info(self.vendorPath .. ' removed')
    end
end

function _M.__:getDependancyFromBox()
    
    local ret = {}
    local boxes = app.boxes
    local order
    for _, box in pairs(boxes) do 
        order = box:order()
        if lf.isArr(order) then
            for k, v in pairs(order) do
                ret[k] = v
            end
        end
    end

    return ret
end

function _M.__:parseDependancy()
    
    local opmRequires = {}
    local jsonStr = fs.get(self.carrierJsonPath)
    local conf = json.decode(jsonStr)
    local dependencies = conf.require
    local boxOrders = self:getDependancyFromBox()

    if lf.notEmpty(boxOrders) then
        dependencies = tb.mergeDict(dependencies, boxOrders)
    end

    local pkgList = {}
    local stub = self:getRockspecStub()

    local includeDev = self:arg('dev')
    if includeDev then
        dependencies = tb.mergeDict(dependencies, conf['require-dev'])
    end

    if dependencies then
        for pkg, version in pairs(dependencies) do
            if not str.has(pkg, '/') then
                tapd(pkgList, '"' .. pkg .. ' ' .. version .. '"')
            else
                tapd(opmRequires, {pkg, version})
            end
        end
        local pkgInfo = str.join(pkgList, ',\n\t')

        stub = str.replace(stub, '{{dependencies}}', pkgInfo, true)

    end

    fs.put(self.rockspecPath, stub)

    return opmRequires
end

function _M.__:buildRepo(repositories)

    local modules, repoPath
    local pathFrom, pathTo, pathDir
    local namespaces = {}
    local appName = self.appName
    local prefix

    for repo, info in pairs(repositories) do
        for ver, data in pairs(info) do
            if #data > 0 then
                data = data[1]
                modules = data.modules
                repoPath = self.vendorPath .. '/' .. repo
                -- fs.makeDir(repoPath)
                for bag, path in pairs(modules) do
                    prefix = str.first(bag, '.')
                    if str.endsWith(path, '.lua') then
                        pathFrom = self.rocksLuaSharePath .. '/' .. path
                        pathTo = repoPath .. '/' .. path
                        namespaces[prefix] = 'vendor .. "' .. prefix .. '"'
                    elseif str.endsWith(path, '.so') then
                        namespaces[prefix] = '"' .. appName .. '-' .. bag .. '"'
                        fs.copy(self.rocksLuaLibPath .. '/' .. bag .. '.so',
                                self.rocksLuaLibPath .. '/' .. appName .. '-' .. bag .. '.so', 'f')
                    end
                end

            end
        end
    end

    self.rocksNamespaces = namespaces
    if fs.exists(self.rocksLuaSharePath) then
        fs.copy(self.rocksLuaSharePath .. '/*', self.vendorPath, 'rf')
    end
    if fs.exists(self.rocksLuaLibPath) then
        fs.copy(self.rocksLuaLibPath .. '/*', self.vendorPath, 'rf')
    end
end

function _M.__:buildAutoloadFile()

    local opmNamespaces = self.opmNamespaces or {}
    local rocksNamespaces = self.rocksNamespaces or {}
    local namespaces = tb.mergeDict(opmNamespaces, rocksNamespaces)
    local stub = self:getAutoloadStub()
    stub = str.replace(stub, '{{namespaces}}', self:tblToLua(namespaces))
    fs.put(self.autoloadFile, stub)
end

function _M.__:getRockspecStub()

    local currDir = lx.getPath(true)

    local stubPath = currDir..'/stub/app.rockspec'

    return fs.get(stubPath)
end

function _M:tblToLua(tbl)

    local t
    local list = {}
    for k, v in pairs(tbl) do
        t = '\t["' .. k .. '"] = ' .. v
        tapd(list, t)
    end

    return str.join(list, ',\n')
end

function _M.__:getAutoloadStub()

    local currDir = lx.getPath(true)

    local stubPath = currDir..'/stub/autoload.lua'

    return fs.get(stubPath)
end

function _M.__:initPaths()

    local appPath = self.appPath
    local vendorPath = appPath .. '/vendor'

    self.vendorPath = vendorPath

    if not fs.exists(vendorPath) then
        fs.makeDir(vendorPath)
    end

    local lxcarrierPath = vendorPath .. '/lxcarrier'
    self.lxcarrierPath = lxcarrierPath

    if not fs.exists(lxcarrierPath) then
        fs.makeDir(lxcarrierPath)
    end

    local rocksTreePath = lxcarrierPath .. '/luarocks-tree'
    if not fs.exists(rocksTreePath) then
        fs.makeDir(rocksTreePath)
    end

    local opmTreePath = lxcarrierPath .. '/opm-tree'
    if not fs.exists(opmTreePath) then
        fs.makeDir(opmTreePath)
    end

    self.rocksTreePath = rocksTreePath
    self.rockspecPath = lxcarrierPath .. '/app-v1-1.rockspec'
    self.rocksManifest = rocksTreePath .. '/lib/luarocks/rocks/manifest'
    self.rocksLuaSharePath = rocksTreePath .. '/share/lua/5.1'
    self.rocksLuaLibPath = rocksTreePath .. '/lib/lua/5.1'
    self.carrierJsonPath = appPath .. '/carrier.json'
    self.autoloadFile = lxcarrierPath .. '/autoload.lua'

    self.opmTreePath = opmTreePath
    self.opmLuaSharePath = self.opmTreePath .. '/lualib'

end

function _M:_get_(key)

    return self.cmd[key]
end

function _M:getCmd()

    return self.cmd
end

function _M:_run_(method)

    return 'getCmd'
end

return _M

