
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

    ngx.log(ngx.ERR, 'init------')
    ngx.timer.every(1, f)

end

function _M:test()

    local lx = require('lxlib')
    local app, lf, tb, str = lx.kit()

    local hc = app('net.http.client')
    local resp = hc:get(
        'http://140.143.49.31/api/ans2?key=xigua&_=' .. lf.time(1), {
            headers = {
                ['User-Agent'] = 'Sogousearch',
                Referer = 'http://wd.sa.sogou.com/',
                Cookie = 'dt_ssuid=1148759995',
            },
        }
    )
 
    local body = resp:getBody()
    body = str.match(body, 'undefined%((.+)%)')
    local info = lf.jsde(body)
    local results = info.result
    local result
    local recommendIndex

    for _, info in ipairs(results) do
        recommendIndex = 0
        info = lf.jsde(info)
        local title = info.title
        warn(title)
        local recommend = info.recommend
        warn(recommend)
        local answers = info.answers
        for i, v in ipairs(answers) do
            if v == recommend then
                recommendIndex = i
            end
        end
 
        if recommendIndex > 0 then
            warn('answer:', recommendIndex)
        end
        local search_infos = info.search_infos
        local search_info = search_infos[1] 
        local searchSummary, searchTitle, searchUrl = search_info.summary, search_info.title, search_info.url
        warn(searchSummary, ';', searchTitle, ';', searchUrl)
    end

end

return _M

