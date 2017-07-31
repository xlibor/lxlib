
local lx, _M = oo{ 
    _cls_ = '',
    _ext_ = 'command',
    sign = {
        makeLib = {
            appName = {short = 'n', index = 1}
        },
        removeLib = {
            appName = {short = 'n', index = 1}
        },
    }
}

local app, lf, tb, str = lx.kit()
local fs = lx.fs
local dp = lx.def.dirSep
local fmt = string.format

function _M:createApp()

    local appName = self:arg(1)
    local parentPath = self.rootPath
    local libPath = self.libPath
    local zipPath = libPath .. '/support/lxdemo.zip'
    local appPath = parentPath .. '/' .. appName
    local envPath = self.envPath
    local defedPath = self:arg('path')

    if defedPath then
        if slen(defedPath) == 0 then
            return self:warn('definition path is empty!')
        end
        if not fs.exists(defedPath) then
            fs.makeDir(defedPath)
        end
        appPath = defedPath .. '/' .. appName
    end

    exec('unzip -q ' .. zipPath .. ' -d ' .. appPath)

    self:envSet('apps.'..appName, {appPath = appName})
    if not self:envGet('defaultApp') then
        self:envSet('defaultApp', appName)
    end

    if fs.exists(appPath) then
        self:info('app created in ' .. appPath)
    else
        self:warn('app created fail.')
    end
end

function _M:removeApp()

    local appName = self:arg(1)
    if lf.isEmpty(appName) then
        self:warn('not input appName.')
        return
    end
    
    local parentPath = self.rootPath
    local appPath = parentPath .. '/' .. appName

    if fs.exists(appPath) then
        local ret = self:confirm('Do you want to remove app('..appPath..'?', false)
        if not ret then
            return
        end
        fs.deleteDir(appPath)
        local defaultApp = self:envGet('defaultApp', '')
        if appName == defaultApp then
            self:envSet('defaultApp', nil)
        end
        self:envSet('apps.'..appName, nil)
        
        self:info('app:'..appName..' removed')
    else
        self:warn('app:'..appName..' not exists')
    end
end

function _M:initApp()

    local appName = self:arg(1)
    local parentPath = self.rootPath
    local libPath = self.libPath
    local appPath = parentPath .. '/' .. appName
    local envPath = self.envPath
    local defedPath = self:arg('path')

    if not fs.exists(appPath) then

        return self:warn('app [' .. appPath .. '] not exists')
    end

    if self:envGet('apps.'..appName) then

        return self:warn('app [' .. appPath .. '] has inited')
    end

    self:envSet('apps.'..appName, {appPath = appName})
    if not self:envGet('defaultApp') then
        self:envSet('defaultApp', appName)
    end

    self:info('app [' .. appPath .. '] inited successfully')

end

function _M:singleApp()

    local appName = self:arg(1)
    local parentPath = self.rootPath
    local libPath = self.libPath
    local appPath = parentPath .. '/' .. appName
    local envPath = self.envPath
    local defedPath = self:arg('path')

    if not fs.exists(appPath) then
        self:warn('app [' .. appPath .. '] not exists')

        return
    end

    self:envSet('apps', {})
    self:envSet('apps.'..appName, {appPath = appName})

    self:envSet('defaultApp', appName)

    self:info('app [' .. appPath .. '] is single')
end

function _M:getDefaultApp()

    local defaultApp = self:envGet('defaultApp')
    if defaultApp then
        self:info(defaultApp)
    else
        self:warn('not set yet')
    end
end

function _M:setDefaultApp()

    local appName = self:arg(1)
    local parentPath = self.rootPath

    if not self:envGet('apps.' .. appName) then

        return self:warn('app [' .. appName .. '] not inited')
    end
    
    self:envSet('defaultApp', appName)
 
    self:info('defaultApp: ' .. appName)
end

function _M:showApps()

    local apps = self:envGet('apps')
    if apps then
        apps = tb.keys(apps)
        self:info(apps)
    else
        self:warn('not inited any app')
    end
end

function _M:makeLib()

    local appName = self:arg(1)
    local parentPath = self.rootPath
    local libPath = self.libPath .. '/lxlib/*'
    local appPath = parentPath .. dp .. appName
    if not fs.exists(appPath) then
        return self:warn(appPath .. ' not exists')
    end
    local vendorPath = str.join({appPath, 'vendor', 'lxlib'}, dp)

    fs.makeDir(vendorPath)
    
    fs.copy(libPath, vendorPath, 'rf'
    )

    self:info('make lib for app:'..appName..' successfully')
end

function _M:removeLib()
 
    local appName = self:arg(1)
    local parentPath = self.rootPath
    local appPath = parentPath .. dp .. appName
    local lib4appPath = appPath .. '/vendor/lxlib'

    if fs.exists(lib4appPath) then
        fs.deleteDir(lib4appPath)
        cheer('remove lib for app:'..appName..' succeed')
    else
        warn('lib for app:'..appName..' not exists')
    end

end

function _M:generateKey()

    local key = lf.guid()
    local show = self:arg('show')
 
    local col = self:getEnvCol()
    col:set('appKey', key)

    local jsonStr = col:toJson(_, true)
    fs.put(self.envPath, jsonStr)

    if show then
        self:comment(key)
    end

    self:line(fmt('application key [%s] set successfully.', key))
end

return _M

