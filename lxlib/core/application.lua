
local _M = {
    _cls_ = '',
    _ext_ = {
        path = 'lxlib.core.container',
    },
    d__ = function(self, key)

        local isShared = self:isShared(key)
        return self:get(key), not isShared
    end
}

local mt = { __index = _M }
local lx = require('lxlib')
local faceBase = require('lxlib.core.face')

local lf, tb, str = lx.f, lx.tb, lx.str
local env, fs, d = lx.env, lx.fs, lx.def
local sfind, ssub = string.find, string.sub

function _M:ctor(basePath, appName, scaffold)

    self.env = env('env') or 'local'
    self.basePath = basePath
    self.name = appName
    self.bags = {}
    self.boxes = {}
    self.faces    = {}
    self.isLookups = {}
    self.bagLookups = {}
    self.booted = false
    self.loaded = false
    self.consoleInited = false
    self:setBasePath(basePath, scaffold)

    self:regCoreBonds()
    self:regBaseBinds()
    self:regBaseBoxes()

    if _G.isLxCmdMode then
        self:initConsole()
    end
end

function _M:initConsole()

    if not self.consoleInited then
        self:reg('consoleSupport', 'lxlib.console.consoleSupportBox')

        for k, v in pairs(self.boxes) do
            self:bootBox(k, v)
        end

        local global = require('lxlib.base.global')
        global.initConsoleGlobal()

        self.consoleInited = true
    end
end

function _M:regCoreBonds()

    self:initCoreBonds()
    self:bond('iterator',           'lxlib.core.bond.iterator')
    self:bond('iteratable',         'lxlib.core.bond.iteratable')
    self:bond('msgProvider',        'lxlib.base.bond.msgProvider')
end

function _M:setBasePath(basePath, scaffold)

    local sep = d.dirSep
    self.basePath = basePath
    local root = basePath .. sep

    if not scaffold then return end

    local app = scaffold.app or 'app'
    local conf = scaffold.conf or 'conf'
    local db = scaffold.db or 'db'
    local map = scaffold.map or 'map'
    local res = scaffold.res or 'res'
    local pub = scaffold.pub or 'pub'
    local tmp = scaffold.tmp or 'tmp'
    local test = scaffold.test or 'test'

    self.scaffold       = scaffold
    self.appDir         = root .. app
    self.appPath        = '.' .. app
    self.confDir        = root .. conf
    self.confPath       = '.' ..  conf
    self.dbDir          = root .. db
    self.dbPath         = '.' ..  db
    self.mapDir         = root .. map
    self.mapPath        = '.' ..  map
    self.resDir         = root .. res
    self.resPath        = '.' ..  res
    self.pubDir         = root .. pub
    self.pubPath        = '.' ..  pub
    self.tmpDir         = root .. tmp
    self.tmpPath        = '.' ..  tmp
    self.testDir        = root .. test
    self.testPath       = '.' ..  test
    self.langDir        = self.resDir .. sep .. 'lang'
    self.langPath       = self.resPath .. '.lang'
end

function _M:getDir(dirType, subDir)

    if not dirType then
        error('dirType not set')
    end

    dirType = dirType .. 'Dir'
    local dir = self[dirType]
    if not dir then
        error('dirType:' .. dir .. ' not defed')
    end

    local ret = dir
    if subDir then
        ret = dir .. d.dirSep .. subDir
    end
    
    return ret
end

function _M:loadWith(loaders)

    self.loaded = true
    local obj
    
    for _, loader in ipairs(loaders) do

        self:bind(loader, loader)
        obj = self:make(loader)
        obj:load(self)
    end

end

function _M:regBaseBoxes()

    self:reg('event',           'lxlib.event.eventBox')
    self:reg('exception',       'lxlib.exception.exceptionBox')
    self:reg('http',            'lxlib.http.httpBox')
    self:reg('routing',         'lxlib.routing.routingBox')
    self:reg('filesystem',      'lxlib.filesystem.fsBox')
end

function _M:regBaseBinds()

    self:bindFrom('lxlib.base', {
        'col', 'msgBag', 'msgPack', 'chain',
        'nameParser', 'viewErrorBag', 'htmlStr',
        {libHelper = 'helper'}, 'timing', 'attr'
    })

    self:bindFrom('lxlib.core', {
        'context', 'box', 'groupBox', 'manager', 'class'
    })

    self:bind('event', 'lxlib.core.event', '')

    self:single('app.timing', function()
        
        return self:make('timing')
    end)
end

function _M:regConfigedBoxes()

    local appConf = self:get('config').app
    local boxes = appConf.boxes
    for _, v in ipairs(boxes) do
        self:reg(v, v)
    end
end

function _M:reg(nick, box)

    if not box then
        box = nick
    end
    
    local boxed = self.boxes[nick]
    if boxed then return boxed end
    box = self:resolveBox(nick, box)
    box:reg()
    
    self:markAsReged(nick, box)
end

function _M:markAsReged(nick, box)

    self.boxes[nick] = box
end

function _M:resolveBox(nick, box)

    local boxType = type(box)
    if boxType == 'string' then
        return self:create(box, box, nil, self)
    elseif boxType == 'table' then
        if box.__cls then 
            return box
        else
            if #box > 0 then
                local implFrom
                box, implFrom = box[1], box[2]
                
                self:bind(implFrom, implFrom)
                self:bind(nick, {box, implFrom}, '')

                return self:make(nick, self)
            end
        end
    elseif boxType == 'function' then
        return box(self)
    else
        error('not support boxType')
    end

end

function _M:prepare(force)
    
    if not self.loaded and not force then 
        return
    end

    local ctx = self:make('context')
    ngx.ctx.lxAppContext = ctx

    return ctx
end

function _M:boot()

    if self.booted then return end
    self.booted = true
     
    self:prepare()

    for k, v in pairs(self.boxes) do
        self:bootBox(k, v)
    end

end

function _M:bootBox(nick, box)

    if not box.booted then
        box:boot()
        box.booted = true
    end
end

function _M:with(bond)

    self:make(bond)
end

function _M:ctx()

    local ctx = ngx.ctx.lxAppContext

    return ctx
end

function _M:getInstanceInCtx(nick)

    local obj
    local ctx = self:ctx()

    local instances = ctx.instances
 
    obj = instances[nick]
 
    return obj
end

function _M:setInstanceToCtx(nick, obj)

    local ctx = self:ctx()

    ctx.instances[nick] = obj
end

function _M:overWith(callback)

    local ctx = self:ctx()

    tapd(ctx.needOvers, callback)
end

function _M:over(ctx)

    ctx = ctx or self:ctx()
    for _, cb in ipairs(ctx.needOvers) do
        cb()
    end
end

function _M:diveWith(callback)

    local ctx = self:ctx()
    tapd(ctx.needDives, callback)
end

function _M:dive(ctx)

    ctx = ctx or self:ctx()
    for _, cb in ipairs(ctx.needDives) do
        cb()
    end
end

function _M:run(cmd, args)

    self:initConsole()
    local kernel = self:make('console.kernel')
    kernel:run(cmd, args or {})

end

function _M:face(name, accessor)

    local cb
    if not accessor then
        accessor = name    
    end

    local typ = type(accessor)
    local isStatic, default

    if typ == 'string' then
        if sfind(accessor, '#') then
            accessor = ssub(accessor, 2)
            isStatic = true
        end

        local i = sfind(accessor, '@')
        if i then
            default = ssub(accessor, i + 1)
            accessor = ssub(accessor, 1, i - 1)
        end
    elseif typ == 'table' then
        accessor, default, isStatic = accessor[1], accessor[2], accessor[3]
    end

    default = default or false
    isStatic = isStatic or false

    local face = faceBase:new(accessor, isStatic, default, self)
    self.faces[name] = face

    local codeCached = lx.global('codeCached')
    if not codeCached then
        lx.G(name, face)
    end
end

function _M:listen(nick, listener)

    nick = nick .. '@*'
    local events = self:get('events')

    if lf.isStr(listener) then
        self:single(listener)
    end
    events:listen(nick, listener)
end

function _M:fire(obj, event, ...)
    
    local events = self:get('events')
 
    events:fire(obj, event, ...)
end

function _M:conf(key, default)

    local config = self._config

    local t = config:get(key)
    
    if default ~= nil and t == nil then
        t = default
    end

    return t
end

function _M:setConf(key, value)

    local config = self._config
    config:set(key, value)
end

function _M:bindFrom(parentDir, bags, options)

    local bagKey, bagName
    local prefix, suffix
    if options then
        prefix = options.prefix
        suffix = options.suffix
    end

    if #bags > 0 then
        for _, bag in ipairs(bags) do
            if type(bag) == 'table' then
                bagKey, bagName = next(bag)
            else
                bagKey, bagName = bag, bag
            end
            if prefix then bagKey = prefix .. bagKey end
            if suffix then bagKey = bagKey .. suffix end
            bagName = parentDir..'.'..bagName

            self:bind(bagKey, bagName)
        end
    elseif next(bags) then
        for bagKey, bagName in pairs(bags) do
            if prefix then bagKey = prefix .. bagKey end
            if suffix then bagKey = bagKey .. suffix end
            bagName = parentDir..'.'..bagName
            
            self:bind(bagKey, bagName)
        end
    end
end

function _M:bondFrom(parentDir, bags)

    local bagKey, bagName

    if #bags > 0 then
        for _, bag in ipairs(bags) do
            if type(bag) == 'table' then
                bagKey, bagName = next(bag)
            else
                bagKey, bagName = bag, bag
            end

            self:bond(bagKey, parentDir..'.'..bagName)
        end
    else next(bags)
        for bagKey, bagName in pairs(bags) do
            self:bond(bagKey, parentDir..'.'..bagName)
        end
    end
end

function _M:bindNamespace(namespace, parentDir, options)

    local excepts, prefix, suffix, ucfirst, name

    if options then
        excepts = options.except
        if excepts then
            excepts = tb.flip(excepts)
        end
        prefix, suffix = options.prefix, options.suffix
        ucfirst = options.ucfirst
        name = options.name
    end

    local files = fs.files(parentDir, 'n', function(file)
        local name, ext = file:sub(1, -5), file:sub(-3)

        if ext == 'lua' then
            if not (excepts and excepts[name]) then
                return name
            end
        end
    end)

    local nick, bag

    for _, file in ipairs(files) do
        bag = namespace .. '.' .. file

        if not (prefix or suffix or name) then
            nick = bag
        else
            nick = file
            if ucfirst then
                nick = str.ucfirst(nick)
            end
            if prefix then
                nick = prefix .. nick
            end
            if suffix then
                nick = nick .. suffix
            end
        end

        self:bind(nick, bag)
    end

end

_M.bindNs = _M.bindNamespace

function _M:runningInConsole()

    return _G.isLxCmdMode
end

_M.isCmdMode = _M.runningInConsole

function _M:runningUnitTests()

    return self.env == 'testing'
end

_M.isTesting = _M.runningUnitTests

function _M:isLocal()

    return self.env == 'local'
end

function _M:isEnv(env)

    return self.env == env
end

function _M:getEnv()

    return self.env
end

function _M:getLocale()

    return self:conf('app.locale')
end

function _M:setLocale(locale)

    -- self['config']:set('app.locale', locale)
    -- self['translator']:setLocale(locale)
    -- self['events']:dispatch(new('events\LocaleUpdated' ,locale))
end

function _M:restore(nick, data, ...)

    local obj = self:make(nick, ...)
    if obj:__is('restorable') then
        obj:restore(data)
    else
        error(nick .. ' not supports restorable')
    end

    return obj
end

function _M:regCmds(callback)

    self:resolving('commander', callback)

end

function _M:__call(key, ...)

    return self:make(key, ...)
end

return _M

