
local _M = {
    _cls_ = ''
}

local libMain = require('lxlib.console.main')

function _M.run(appName, rootPath)

    _G.isLxTaskMode = true

    local global = require('lxlib.base.global')
    global.initConsole(rootPath, true)

    local lx = require('lxlib')
    local lf, fs, json = lx.f, lx.fs, lx.json
    local dp = lx.def.dirSep

    rootPath = lf.rtrim(rootPath, '[/\\]')
    
    local appEnv, envPath, currApp
    local appName, appPath = 'lxlib', rootPath
    local currPath = fs.currDir()

    if fs.exists(currPath .. '/main.lua') then
        appName = fs.baseName(currPath)
        envPath = currPath .. '/env.json'
        appPath = currPath
        currApp = appName
    else
        local pubEnv = lx.g('pubEnv')
        local defaultApp = pubEnv.defaultApp
        if defaultApp then
            appName = defaultApp
            local apps = pubEnv.apps
            local appInfo = apps[appName]
            appPath = appInfo.appPath
            if not string.find(appPath, '[\\/]+') then
                appPath = rootPath .. '/' .. appPath
            end
            envPath = appPath .. '/env.json'
        end
    end

    if appName ~= 'lxlib' then
        package.path = package.path .. ';'
            .. appPath .. '/?.lua;'
            .. appPath .. '/vendor/?.lua;;'

        package.cpath = package.cpath .. ';'
            .. appPath .. '/vendor/?.so;;'
    end

    if fs.exists(envPath) then
        appEnv = json.decode(fs.get(envPath))
        appEnv.appEnvPath = envPath
    end

    lx.initEnv(appEnv)

    local env = lx.env
    
    env:set('appPath', appPath)
    env:set('appName', appName)
    env:set('rootPath', rootPath)
    env:set('currApp', currApp)
    ngx.ctx.lxAppName = appName
    ngx.ctx.lxAppPath = appPath
    ngx.ctx.libRootPath = rootPath

    local useCjson = env('useCjson')
    if useCjson then

        json.useCjson()
    end

    local app = require('.load.app')

    local kernel = app:make('console.kernel')
    kernel:load()
     
    local f = function(sign)
        if sign then
            return
        end
        ngx.ctx.lxAppName = appName
        ngx.ctx.lxAppPath = appPath
        ngx.ctx.libRootPath = rootPath
        app:prepare(true)

        kernel:runSchedule()
    end

    ngx.log(ngx.ERR, 'taskLoad--')
    ngx.timer.every(1, f)

end

return _M

