
local _M = {
    _cls_           = '',
    inited          = false,
    pubEnv          = {},
    appPaths        = {},
    appNamespaces   = {},
    apps            = {}, 
    closures        = {},
    GG              = _G,
    multiApp        = false,
    codeCached      = false,
}

if type(_G.isLxCmdMode) == 'nil' then
    _G.isLxCmdMode = false
end

local lx = require('lxlib')
local lf, Str, tb = lx.f, lx.str, lx.tb

local loadedMods        = {}
local wrappers          = {}
local need = require

local libNeeds = {
    ['lxlib.base.global'] = 1,
    ['lxlib.filesystem.fs'] = 1
}
local multiApp = false

local sfind, ssub, sgsub, smatch, sbyte = string.find, string.sub, string.gsub, string.match, string.byte
local tmaxn = table.maxn

_G.Lx = function()
    local lx = require('lxlib')
    
    return lx
end

local rawunpack = unpack
_G.unpack = function(tbl, begin, length)

    begin = begin or 1
    length = length or tmaxn(tbl)
    return rawunpack(tbl, begin, length)
end

_G.__require = need

_G.oo = function(cls, mtTable)
    
    if not mtTable then
        local lib = require('lxlib')
        if not cls._cls_ then
            lx.throw('badFunctionCallException', 'invalid oo')
        end

        lib.load(cls, 1)

        return lib, cls, {__index = cls}, cls.__
    else
        setmetatable(cls, mtTable)
        return cls
    end
end

local clsesMt = {}
clsesMt.__call = function(this, subCls)
    local lib = require('lxlib')
    local subClsName = subCls._cls_
    this[subClsName] = subCls
    lib.load(subCls, 1)

    return subCls
end

_G.oos = function()
    local clses = {
        _clses_ = ''
    }
    setmetatable(clses, clsesMt)

    local lib = require('lxlib')
 
    return lib, clses
end

_G.New = function(nick, ...)

    local lx = require('lxlib')
    local new = lx.new

    return new(nick, ...)
end

_G.Env = function(key, default)

    local lx = require('lxlib')
    local env = lx.env

    return env(key, default)
end

_G.Each = function(tbl)
    if #tbl > 0 then
        return ipairs(tbl)
    else
        return pairs(tbl)
    end
end

_G.Fun = function(key, callback)
    if not callback then
        callback = key
        key = nil
    end
    local closure = require('lxlib.base.closure'):new(callback, key)

    if key then
        _M.closures[key] = closure
    end
    return closure
end

_G.Col = function(...)
    local col = lx.col(...)
    col.autoDerive = true

    return col
end

_G.With = function(tbl, cb)

    setfenv(cb, tbl)()
end

_G.Use = function(cls)
    
    local lx = require('lxlib')
    return lx.use(cls)
end

_G.Fmt = Str.fmtv

_G.Compact = function(...)

    local vars, varCount = lf.needArgs(...)
    local vars = tb.flip(vars, true)
    local index = 1
    local gotCount = 0
    
    while true do
        local varName, varValue = debug.getlocal(2, index)
        if not varName then break end
        if vars[varName] then
            vars[varName] = varValue
            gotCount = gotCount + 1
        end
        index = index + 1
        if gotCount >= varCount then
            break
        end
    end

    return vars
end

_G.dd = function(...)
    
    local vars, len = lf.getArgs(...)

    if len == 0 then
        echo('type:nil     ')
        return
    end

    for i = 1, len do
        local var = vars[i]
        local vt = type(var)
        local content
        if vt == 'table' then
            if var.__cls and not var.__cls == 'col' then
                content = var.__cls
            else
                tb.removeFunc(var)
                content = lx.json.encode(var)
            end
        elseif vt == 'function' then
            content = ''
        else
            content = var
        end

        echo('type:', vt, ',info:', content, '     ')
    end

    ngx.eof()
end

local loadMod = function(namespace)
    
    local mod
    local t
    local namespaceArg = namespace

    if namespace == 'lxlib' then
        -- namespace = 'lxlib.init'
    end

    local prefix
    local posBegin, posEnd = sfind(namespace, '.', nil, true)
    if posBegin and posBegin > 1 then
        prefix = ssub(namespace, 1, posBegin - 1)
    else
        prefix = namespace
    end
    local first = sbyte(namespace)

    local lxAppName
    if _G.isLxCmdMode then
        lxAppName = ngx.ctx.lxAppName
    else
        lxAppName = ngx.var.lxAppName
    end

    local appName = lxAppName

    if first == 46 then
        namespace = appName .. namespace
    elseif prefix == 'lxlib' and libNeeds[namespace] then
        return need(namespace)
    elseif prefix == 'lxlib' and multiApp then
        namespace = appName .. '.vendor.' .. namespace
    else
        local appNamespace = _M.appNamespaces[appName]
        if appNamespace then
            if prefix == 'resty' then
                posBegin, posEnd = sfind(namespace, '.', 7, true)
                if posBegin and posBegin > 1 then
                    prefix = ssub(namespace, 1, posBegin - 1)
                else
                    prefix = namespace
                end
            end
            t = appNamespace[prefix]
            if t then
                if posEnd then
                    namespace = t .. '.' .. ssub(namespace, posEnd + 1)
                else
                    namespace = t
                end
            else

            end
        end
    end

    mod = loadedMods[namespace]

    if mod then
       return mod
    end

    local ok, mod = pcall(need, namespace)
 
    if ok then
        local wrapper = wrappers[namespaceArg]

        if wrapper then
            wrapper = require(wrapper)
            wrapper(mod)
        end

        loadedMods[namespace] = mod
        return mod
    end

    error(mod, 2)
end

function _M.setWrapper(src, dst)

    wrappers[src] = dst
end

function _M.getWrappers()

    return wrappers
end

function _M.ensureEnvFile(rootPath)

    local fs = lx.fs
    local envPath = rootPath .. '/lxpub/env.json'

    if not fs.exists(envPath) then
        local original = rootPath .. '/lxlib/support/env.json'
        fs.copy(original, envPath)
    end

    return envPath
end

function _M.initConsole(rootPath, isTaskMode)

    local fs, json = lx.fs, lx.json
 
    local envPath = _M.ensureEnvFile(rootPath)
    local env

    if fs.exists(envPath) then
        local envStr = fs.get(envPath)
        env = json.decode(envStr)
    end

    _M.envPath = envPath
    _M.pubEnv = env
    _M.lxInited = true
    
    _M.loadGlobalFunc(isTaskMode)
    _M.initConsoleGlobal(isTaskMode)
    _G.require = loadMod

end

function _M.initConsoleGlobal(isTaskMode)

    _G.exec = function(s)
        return os.execute(s)
    end

    _G.warn = function(s)
        if isTaskMode then
            ngx.log(ngx.ERR, s)
        else
            exec(fmt([[echo -e "\033[31m%s \033[0m"]], s))
        end
    end

    _G.cheer = function(s)
        if isTaskMode then
            ngx.log(ngx.ERR, s)
        else
            exec(fmt([[echo -e "\033[32m%s \033[0m"]], s))
        end
    end

end

function _M.init(initTimer)

    _M.inited = true
    local fs, json = lx.fs, lx.json

    local env
    local rootPath
    local currPath = lx.getPath()
    if sfind(currPath, '/lxlib/lxlib/') then
        currPath = sgsub(currPath, '/lxlib/lxlib/', '/lxlib/')
    end

    if lx.f.isWin() then
        rootPath = sgsub(currPath, '\\lxlib\\base\\global.lua', '')
    else
        rootPath = sgsub(currPath, '/lxlib/base/global.lua', '')
    end

    local envPath = _M.ensureEnvFile(rootPath)

    if fs.exists(envPath) then
        local envStr = fs.get(envPath)
        env = json.decode(envStr)
        env.rootPath = rootPath
        local apps = env.apps
        local appPath
        local dp = lx.def.dirSep
        local reged = 0

        for k, v in pairs(apps) do
            appPath = v.appPath
            if not sfind(appPath, '[\\/]+') then
                appPath = rootPath .. dp .. appPath
            end

            if fs.exists(appPath) then
                v.appPath = appPath
                _M.appPaths[k] = appPath
                package.path = package.path .. ';'
                    .. appPath .. '/?.lua;'
                    .. appPath .. '/vendor/?.lua;;'

                package.cpath = package.cpath .. ';'
                    .. appPath .. '/vendor/?.so;;'

                if initTimer and v.enableTask then
                    _M.initTaskTimer(k, rootPath)
                end
                reged = reged + 1
            end
        end

        if reged > 0 then
            _G.require = loadMod
        end

        if reged > 1 then
            multiApp = true
        end

    end

    _M.multiApp = multiApp
    _M.pubEnv = env
    _M.lxInited = true
    _M.loadGlobalFunc()
    
    local g = _M.GG
    local gmt = getmetatable(g)

    if not gmt then
        _M.codeCached = true
        setmetatable(g, {
            __index = function(this, key)
                local t
                local lx = require('lxlib')
                local app = lx.app()
                local faces = app.faces
                if faces and faces[key] then
                    t = faces[key]
                end
                if not t and env.globalVarCheck then
                    error('global var:' .. key)
                end
                return t
            end
        })
    end

end

function _M.initTaskTimer(appName, rootPath)

    _G.isLxCmdMode = true
    ngx.ctx.lxAppName = appName
    local f = function(sign)
        local taskLoader = require('lxlib.app.taskLoader')
        taskLoader.run(appName, rootPath)
    end

    ngx.timer.at(0, f)
end

function _M.loadGlobalFunc(isTaskMode)

    if isTaskMode then
        ngx.say = function(...)
            ngx.log(ngx.ERR, ...)
        end
    end

    _G.print = ngx.say
    _G.echo = function(p1, ...)
        if type(p1) == 'table' then
            ngx.say(lx.json.encode(p1))
        else
            ngx.say(p1, ...)
        end
    end
    _G.tapd = function(t, v, ensure)
        if not ensure then
            t[#t+1] = v
        else
            if not v then
                if type(v) == 'nil' then
                    v = ngx.null
                end
            end
            t[#t+1] = v
        end
    end

    _G.fmt = string.format
    _G.jsen = lx.json.encode
end

function _M.addNamespaces(namespaces)

    local appName = ngx.ctx.lxAppName
    _M.appNamespaces[appName] = namespaces

end

function _M.set(key, value)

    _G[key] = value
end

function _M.get(key)

    return _G[key]
end

return _M

