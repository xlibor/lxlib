
local _M = {
    _cls_       = '',
    version     = '0.8.02',
    f           = require('lxlib.base.pub'),
    str         = require('lxlib.base.str'),
    tb          = require('lxlib.base.arr'),
    n           = require('lxlib.core.initer'),
    json        = require('lxlib.json.base'),
    db          = require('lxlib.db.init'),
    def         = require('lxlib.base.define'),
    fs          = require('lxlib.filesystem.fs')
}

local Str = _M.str

local mt = {}
setmetatable(_M, mt)

function _M.serve()

    return require('lxlib.app.webLoader').run()
end

function _M.run(args, rootPath)

    _G.isLxCmdMode = true
    return require('lxlib.app.cmdLoader').run(args, rootPath)
end

function _M.getPath(onlyDir, stackLevel)

    stackLevel = stackLevel or 0
    stackLevel = stackLevel + 2
    local filePath = debug.getinfo(stackLevel, 'S').source
    local t = filePath:sub(2)
    if onlyDir then
        local fs = _M.fs
        return fs.split(t)
    end

    return t
end

function _M.getFunc(stackLevel)

    stackLevel = stackLevel or 1
    stackLevel = stackLevel + 1
    local info = debug.getinfo(stackLevel, 'n')
    local ntype, name = info.namewhat, info.name

    return name
end

function _M.trace(stackLevel)

    stackLevel = stackLevel or 1
    stackLevel = stackLevel + 1

    local info = debug.getinfo(stackLevel, 'Sn')
    local filePath = info.source
    filePath = filePath:sub(2)

    local ntype, name = info.namewhat, info.name

    return {
        file = filePath,
        func = name
    }
end

_M.d = _M.def
_M.pub = _M.f 
_M.col = _M.n.col
_M.obj = _M.n.obj
_M.arr = _M.n.arr

function _M.app()

    local app = _M._app

    return app
end

function _M.try(...)

    local app = _M.app()
    return app:make('exception.trigger', ...)
end

function _M.throw(...)

    local raiserCtor = require('lxlib.exception.raiser')

    return raiserCtor:raise(...)
end

function _M.she()

    local app = _M.app()
    local trigger = app:make('exception.trigger')

    return trigger:she()
end

function _M.call(cls, defaultMethod, ...)
 
    local vt = type(cls)
    local app = _M.app()
    local obj, func

    if vt == 'function' then
        return cls(...)
    elseif vt == 'string' then
        obj = app:make(cls)
        func = obj[defaultMethod]
        func(obj, ...)
    elseif vt == 'table' then
 
    end
end

function _M.new(bag, ...)

    local app = _M.app()

    return app:make(bag, ...)
end

function _M.global(key, value)

    local global = require('lxlib.base.global')
    if type(value) ~= 'nil' then
        global[key] = value
    else
        return global[key]
    end
end

_M.g = _M.global

function _M.Global(key, value)

    local global = require('lxlib.base.global')
    if value then
        global.set(key, value)
    else
        return global.get(key)
    end
end

_M.G = _M.Global

function _M.initEnv(appEnv)

    local env

    if isLxCmdMode then

        env = require('lxlib.base.env'):new(_M.g('pubEnv'), appEnv)
        _M.env = env
        
        return env
    end

    if not _M.env then
        env = require('lxlib.base.env'):new(_M.g('pubEnv'), appEnv)
        _M.env = env
    end
end

function _M.addApp(app, appName)
    
    _M._app = app

    local apps = _M.g('apps')
    apps[appName] = app
end

function _M.kit()
    
    return _M.app(), _M.f, _M.tb, _M.str, _M.new
end

function _M.kit2()
    
    return _M.use, _M.try, _M.throw
end

if not math.mod then
    math.mod = math.fmod
end

function _M.mm()
    
    return _M.n.obj, _M.n.arr
end

function _M.init()

    require('lxlib.base.global').init()
end

function _M.load(cls, isLxCall)

    local env = _M.env
    local scopeCheck 
    if env then 
        scopeCheck = env('scopeCheck')
    end

    local callLevel = isLxCall and 3 or 2
    local filePath = debug.getinfo(callLevel,'S').source
    filePath = filePath:sub(2)
    local fs = _M.fs

    local privates = {}
    if scopeCheck then
        local clses = _M._clses
        if not clses then
            clses = {}
            _M._clses = clses
        end

        privates._clsPath = filePath
        privates._cls = cls.__cls
        clses[filePath] = cls.__cls
    end

    cls.__ = privates
    cls.d__ = {}
    cls.c__ = {}
    cls.__dir = filePath

    if cls._static_ then
        cls.s__ = {}
        cls.t__ = {}
    end
    
    return _M
end

function _M.dir(dirType, subDir)

    local app = _M.app()
    return app:getDir(dirType, subDir)
end

function _M.use(...)

    local app = _M.app()
    local args = {...}
    local len = #args

    if len == 1 then
        return app:use(args[1])
    elseif len > 1 then
        local t = {}
        for _, v in ipairs(args) do
            t[#t + 1] = app:use(v)
        end
        return unpack(t)
    end
end

function _M.namespace(ns)

    if type(ns) == 'table' then
        ns = ns.__nick
        if not ns then
            error('invalid namespace type')
        end
        local lastP = Str.rfind(ns, '%p')
        if lastP then
            ns = Str.sub(ns, 1, lastP - 1)
        end
    end

    if Str.find(ns, '@') then
        ns = Str.divide(ns, '@')
    end

    local useWithNs = function(...)
        local app = _M.app()
        local args = {...}
        local len = #args

        if len == 1 then
            return app:use(ns .. '.' .. args[1])
        elseif len > 1 then
            local t = {}
            for _, v in ipairs(args) do
                t[#t + 1] = app:use(ns .. '.' .. v)
            end
            return unpack(t)
        end
    end

    local newWithNs = function(bag)
        if string.sub(bag, 1, 1) == '@' then
            bag = ns .. bag
        else
            bag = ns .. '.' .. bag
        end
        return _M.new(bag)
    end

    return useWithNs, newWithNs
end

_M.ns = _M.namespace

mt.__call = function(self, cls)

    _M.load(cls, true)

    return cls, _M
end

return _M

