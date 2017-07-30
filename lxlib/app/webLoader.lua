
local _M = {
    _cls_ = ''
}

function _M.run()

    local appName = ngx.var.lxAppName
    if not appName then
        return ngx.say('not set lxAppName')
    end

    ngx.ctx.lxAppName = appName
    
    local global = require('lxlib.base.global')

    local inited = true
    if not global.inited then
        global.init()
        inited = false
    end

    local appPaths = global.appPaths
    local appPath = appPaths[appName]

    if appPath then
        ngx.ctx.lxAppPath = appPath
    else
        return ngx.say('app path invalid')
    end

    local lx = require('lxlib')
    local lf, fs, json = lx.f, lx.fs, lx.json
    
    local env, appEnv

    if not lx.env then
        local appEnvPath = appPath .. '/env.json'
        if fs.exists(appEnvPath) then
            appEnv = json.decode(fs.get(appEnvPath))
        end

        lx.initEnv(appEnv)
        env = lx.env
    else
        env = lx.env
    end

    local appMainPath = '.index'
    local appMain = require(appMainPath)
    local envType = env('env')
    
    if not inited then
        local useCjson = env('useCjson')
        if useCjson then

            json.useCjson()
        end
    end

    if envType == 'local' then
        local ok, err, trace = lf.try(appMain)
        if not ok then
            echo(err)
            echo(trace)
        end
    else
        appMain()
    end
end

return _M

