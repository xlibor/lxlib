
local _M = {
    _cls_    = ''
}

local mt = { __index = _M }
local lx = require('lxlib')
local lf, tb, str = lx.f, lx.tb, lx.str
local fs = lx.fs
local sfind, slen = string.find, string.len

local scopeCheck = false
local bondCheck = false
local typeCheck = false

local docParser = require('lxlib.doc.base.parser')
local typeChecker = require('lxlib.core.typeChecker')
local App

function _M:new(app)

    local this = {
        app = app
    }
    App = app

    setmetatable(this, mt)
    this:init()

    return this
end

function _M:init()
    
    local env = lx.env
    if env then
        scopeCheck = env:get('scopeCheck')
        bondCheck = env:get('bondCheck')
        typeCheck = env:get('typeCheck')
    else
        error('lx env not loaded')
    end
end

local function getBagCode(path)

    local file = io.open(path, "r")
    if not file then
        error('get bag code failed:' .. path)
    end
    local content = file:read "*a"
    file:close()

    return content
end

local function getFileName(bagName)

    local paths = str.split(bagName, '.')
    if paths then
        return paths[#paths]
    end
end

local function runSuperMethod(obj, index, method, ...)

    local app, t
    local firstArg, methodName, curCls
    local indexGiven

    local vt = type(index)
    if vt == 'string' then
        firstArg = method
        methodName = index
        index = 1
    elseif vt == 'table' then
        curCls = index.__cls
        index = 1
        methodName = method
    elseif vt == 'number' then
        methodName = method
        indexGiven = true
    end

    if index < 1 then
        return
    end

    local mtList = obj.__mtList

    if #mtList > 2 and not curCls and not indexGiven then
        t = debug.getinfo(2,'S').source:sub(2)

        app = App
        local info = app.bagLookups[t]
        if info and info.cls then
            curCls = info.cls
        end
    end

    local mt

    if curCls then
        local i = 0
        for _, e in ipairs(mtList) do

            if curCls == e.__cls then
                break
            end
            i = i + 1
        end

        index = index + i
    end

    mt = mtList[index + 1]
    if not mt then
        for i = index + 2, #mtList do 
            mt = mtList[methodName]
            if mt then break end
        end
        if not mt then
            error('not find super method:'..methodName)
        end
    end

    local mtMethod = mt[methodName]
    if mtMethod then
        if firstArg then
            return mtMethod(obj, firstArg, ...)
        else
            return mtMethod(obj, ...)
        end
    end
end

local function _isInstanceOf(obj, cls)
    
    local clsType = type(cls)
    local clsName
    local objCls, objNick = obj.__cls, obj.__nick
    local mtList
    local bond
    local bondList

    if clsType == 'table' then
        clsName = cls.__cls
        if clsName == objCls then
            return true
        end
        
        mtList = obj.__mtList
        for _, mt in ipairs(mtList) do
            if clsName == mt.__cls then
                return true
            end
        end
    elseif clsType == 'string' then
        clsName = cls
        if clsName == objCls then
            return true
        end
        if objNick then
            if clsName == objNick then 
                return true
            end
        end
        local bondInfo, bondFrom
        mtList = obj.__mtList
        if mtList then
            for _, mt in ipairs(mtList) do
                if clsName == mt.__cls then
                    return true
                end
            end
        end

        bondList = obj.__bonds
        if next(bondList) then
            if bondList[clsName] then
                return true
            end
        end
    end

end

local function isInstanceOf(obj, clsList)

    local argType = type(clsList)
    if argType == 'table' then
        if clsList.__cls then
            clsList = clsList.__cls
            argType = 'string'
        else
            error('invalid type')
        end
    end

    local app = App
    if not app then
        error('path:' .. objName)
    end

    if argType == 'string' then
        local bindInfo = app.binds[clsList]
        if bindInfo then
            clsList = bindInfo.bag
        end
    end

    local typeName
    local objName, bagPath = obj.__cls, obj.__path
    local ret

    local isLookups = app.isLookups

    local curLookup = isLookups[bagPath]
    if not curLookup then
        curLookup = {}
        isLookups[bagPath] = curLookup 
    end

    if argType == 'string' then
        typeName = clsList
        ret = curLookup[typeName]
        if ret then
            return (ret == 1) and true or false
        end
        ret = _isInstanceOf(obj, typeName) or false
        curLookup[typeName] = ret and 1 or 0

        return ret
    else
        error('invalid type')
    end
end

local function runScopeCheck(obj, baseMt, key)

    local checkFail
    local curCls, curPath, defInPath, defInCls
    local filePath = debug.getinfo(3,'S').source
    curPath = filePath:sub(2)
    local priList = baseMt.__priList

    if priList then
        for k, v in pairs(priList) do
            checkFail = false
            if v[key] then
                defInPath = v._clsPath
                if defInPath ~= curPath then
                    defInCls = v._cls
                    curCls = lx._clses[curPath]
                    if not curCls then
                        checkFail = true
                    else
                        if not obj:__is(curCls) then

                            checkFail = true
                        end
                    end
                    if checkFail then
                        -- error('private/protected method '..key..' in ' .. v._clsPath..' can not be used in '..curPath)
                    end
                end
            end
        end
    end
end

local function setObjItem(obj, key, item, needSet)
    
    if needSet or not scopeCheck then 
        rawset(obj, key, item)
    end
end

local function extendMtTable(this, app, defer, run, get, baseMt, key)
    
    local node

    local func
    local t, vt

    if scopeCheck then
        runScopeCheck(this, baseMt, key)
    end

    node = baseMt[key]
    if node then
        setObjItem(this, key, node)

        return node
    end

    if defer then
        local deferType = type(defer)
        if deferType == 'table' then
            local deferCb = defer[key]
            if deferCb then
                node = deferCb(this)
                setObjItem(this, key, node)

                return node
            end
        elseif deferType == 'function' then
            node = defer(this, key)
            setObjItem(this, key, node)

            return node
        else
            error('unsupport defer type')
        end
    end

    local getFirst = false
    if run and get then
        if baseMt._get_run_ then 
            getFirst = true
            node = get(this, key)
            vt = type(node)
            if not (vt == 'function' or vt == 'nil')  then

                return node
            end
        end
    end

    if run then

        local saveToMt = true
        local runDef, cancelSaveToMt = run(this, key)
        if cancelSaveToMt then
            saveToMt = false
        end

        local typ = type(runDef)

        if typ == 'function' then 
            node = runDef
        elseif typ == 'table' then
            if #runDef > 0 then
                for _, linkObj in ipairs(runDef) do
                    func = linkObj[key] 
                    if type(func) == 'function' then
                        node = function(this, ...)
                            return func(linkObj, ...)
                        end

                        break
                    end
                end
            else
                func = runDef[key] 
                if type(func) == 'function' then
                    node = function(this, ...)

                        return func(runDef, ...)
                    end
                end
            end
        elseif typ == 'string' then

            local linkFunc = baseMt[runDef]
            if type(linkFunc) == 'function' then
                local linkObj = linkFunc(this)
                if linkObj then
                    func = linkObj[key]
                    vt = type(func)
                    if vt == 'function' then
                        node = function(this, ...)
                            linkObj = linkFunc(this)
                            return func(linkObj, ...)
                        end
                    else
                        node = func
                        saveToMt = false
                    end
                end
            end
        else
            error('invalid run type')
        end

        if node then
            setObjItem(this, key, node, getFirst)
            if saveToMt then
                baseMt[key] = node
            end

            return node
        end
    end

    if get and not getFirst then
        node = get(this, key)
        if type(node) ~= 'function' then

            return node
        end
    end
end

local function extendNewindex(this, set, key, value)
 
    if set then
        set(this, key, value)
    end
end

local function methodExists(obj, method)

    local baseMt  = obj.__baseMt

    if baseMt[method] then
        return true
    end
 
    return false
end

local function objInvokeMethod(obj, method, ...)

    local action = obj[method]

    if action then
        return action(obj, ...)
    else
        error('invalid method[' .. method .. ']')
    end
end

local function makeNewSelf(obj, ...)

    local bagPath = obj.__path
    local nick = rawget(obj, '__nick')
    local app = App

    local obj = app:create(nick, bagPath, nil, ...)

    return obj
end

local function makeClone(obj)

    local bagPath = obj.__path
    local app = App
    local newObj = {}

    for k, v in pairs(obj) do
        if type(v) ~= 'function' then
            newObj[k] = v
        end
    end

    local mt = getmetatable(obj)
    setmetatable(newObj, mt)

    local cloneCb = obj.__cloneCb
    if cloneCb then
        cloneCb(obj, newObj)
    end
    
    return newObj
end

local function useObjStatic(obj, key, value)

    local static = obj.__staticBak

    if static then
        if not value then
            return static[key]
        else
            rawset(static, key, value)
        end
    end
end

local function bondFromCheck(app, cls, notImpls)

    local bondInfo = cls._bond_
    if not bondInfo then return end

    local vt = type(bondInfo)
    if vt == 'string' then 
        bondInfo = {from = {bondInfo}}
    elseif vt == 'table' then
        if #bondInfo > 0 then
            bondInfo = {from = bondInfo}
        end
    end
 
    local bondFrom = bondInfo.from
    
    if bondFrom then
        if type(bondFrom) == 'string' then
            bondFrom = {bondFrom}
        end
        local methodList
        local deferInfo
        for _, bondName in ipairs(bondFrom) do
            methodList = app:getBond(bondName)
            if methodList then
                deferInfo = cls.d__ or {}
                for _, v in pairs(methodList) do
                    if not cls[v] then
                        if notImpls then
                            notImpls[v] = v
                        else
                            if not deferInfo[v] then
                                error(cls.__cls .. ' not impl method:' .. v)
                            end
                        end
                    end
                end
            else
                error(fmt('bond [%s] for [%s] not exists', bondName, cls.__cls))
            end
        end
    end
end

local function bondDefCheck(app, bag, super, notImpls)

    local bondInfo, bondDef, bondFrom, bondDefList, bondFromList
    local methodList

    bondFromCheck(app, bag, notImpls)

    if super then
        local newNotImpls = {}

        bondInfo = super._bond_
        if bondInfo then
            bondDef = bondInfo.def
            if bondDef then
                if #bondDef > 0 then
                    for _, v in ipairs(bondDef) do
                        if notImpls[v] then
                            notImpls[v] = nil
                        end
                        if not bag[v] then
                            newNotImpls[v] = v
                        end
                    end
                elseif next(bondDef) then
                    for k, v in pairs(bondDef) do
                        if notImpls[k] then
                            notImpls[k] = nil
                        end
                        if not bag[k] then
                            newNotImpls[k] = k
                        end
                    end
                end
            end

            if type(bondInfo) == 'string' then
                bondInfo = { from = {bondInfo} }
            end

            bondFrom = bondInfo.from
            if bondFrom or #bondInfo > 0 then
                if super.a__ then
                    bondFromCheck(app, super, notImpls)
                else
                    bondFromCheck(app, super)
                end
            end

            if next(notImpls) then
                for k, v in pairs(notImpls) do
                    newNotImpls[k] = k
                end
            end
        end

        return newNotImpls
    end
end

local function checkLastBagBondDef(bagPath, bag, notImpls)

    if next(notImpls) then
        for k, v in pairs(notImpls) do
            if bag[k] then notImpls[k] = nil end
        end
 
        if next(notImpls) then
            for k, v in pairs(notImpls) do
                error(bagPath .. ' not impl method:' .. k)
            end
        end
    end
end

local function diToObj(app, bagCtor, obj, diDefs)

    local args = {}
    local tObj
    for _, v in pairs(diDefs) do
        tObj = app:get(v)
        tapd(args, tObj)
    end

    bagCtor(obj, unpack(args))
end

function _M:create(nick, bagPath, superObj, ...)

    local app = App

    local obj

    if type(bagPath) == 'table' then
        bagPath = bagPath.__path
    end

    local classInfo = self:getClassInfo(bagPath)

    local cacheInfo = classInfo.cache
    local bagNew = classInfo.new

    local bag, objMt = classInfo.bag, classInfo.objMt
    local mtNeedNew = classInfo.mtNeedNew
 
    local ctorList = classInfo.ctorList
    local mixinCtors = classInfo.mixinCtors
    local superCtor
 
    if superObj then
        superCtor = superObj.ctor
        obj = superObj
    else
        if bagNew then
            obj = bagNew(mtNeedNew, ...)
        end
    end

    if not obj then
        obj = {}
    end

    rawset(obj, '__nick', nick)

    if classInfo.needExtend then
        setmetatable(obj, objMt)
    elseif bag.__cls then

    end
     
    rawset(obj, '__skip', false)
    for _, ctor in ipairs(ctorList) do
        if not obj.__skip then
            if not superObj then
                ctor(obj, ...)
            else
                if superCtor then
                    if superCtor == ctor then
                        break
                    else
                        ctor(obj, ...)
                    end
                else
                    ctor(obj, ...)
                end
            end
        end
    end

    if #mixinCtors > 0 then
        for _, ctor in ipairs(mixinCtors) do
            ctor(obj, ...)
        end
    end
 
    if cacheInfo then
        obj._cached_ = {}
    end
 
    return obj
end

function _M:mergeMixin(bag, mixins, mixinCtors)

    local app = App

    local mixinInfo = bag._mix_

    if not mixinInfo then
        return
    end

    local currMixinList
    local vt = type(mixinInfo)
    if vt == 'string' then
        currMixinList = {mixinInfo}
    elseif vt == 'table' then
        currMixinList = mixinInfo
    end
     
    local mixBag, t

    for _, mix in ipairs(currMixinList) do

        local bindInfo = app.binds[mix]
        if bindInfo then
            mixBag = lf.import(bindInfo.bag)
        else
            mixBag = lf.import(mix)
        end

        tapd(mixins, mixBag)

        self:mergeMixin(mixBag, mixins, mixinCtors)

        local deferInfo, cacheInfo, runInfo =
            mixBag.d__, mixBag.c__, mixBag._run_
        local getInfo, setInfo = mixBag._get_, mixBag._set_
        local cloneInfo = mixBag._clone_
        local privates = mixBag.__
        local mixCtor = mixBag.ctor

        if deferInfo then
            if not bag.d__ then
                bag.d__ = {}
            end
            for k, v in pairs(deferInfo) do
                t = bag.d__[k]
                if not t then bag.d__[k] = v end
            end
        end

        if cacheInfo then
            if not bag.c__ then
                bag.c__ = {}
            end
            for k, v in pairs(cacheInfo) do
                t = bag.c__[k]
                if not t then bag.c__[k] = v end
            end
        end

        if runInfo then
            if not bag._run_ then
                bag._run_ = runInfo
            end
        end

        if getInfo then
            if not bag._get_ then
                bag._get_ = getInfo
            end
        end

        if setInfo then
            if not bag._set_ then
                bag._set_ = setInfo
            end
        end

        if cloneInfo then
            if not bag._clone_ then
                bag._clone_ = cloneInfo
            end
        end

        if privates and next(privates) then
            if not bag.__ then
                bag.__ = {}
            end
            for k, v in pairs(privates) do
                t = bag.__[k]
                if not t then bag.__[k] = v end
            end
        end

        for k, v in pairs(mixBag) do
            if type(v) == 'function' then
                t = bag[k]
                if not t then bag[k] = v end
            end
        end

        if mixCtor then
            tapd(mixinCtors, mixCtor)
        end
    end

end

function _M:getClassBaseInfo(bagPath)

    local app = App

    local baseInfo = app.classBaseInfos[bagPath]

    if baseInfo then 
        return baseInfo
    else
        baseInfo = {}
    end

    local bag = lf.import(bagPath)
    local filePath = bag.__dir

    if filePath then
        if typeCheck then
            local defedMethods = docParser.getAnnotations(filePath)
            if defedMethods then
                -- typeChecker:new(bag, defedMethods):check()
            end
        end
    else
        -- error('invalid')
    end

    local autoInfo = bag._auto_
    if autoInfo then
        local both, method
        for k, v in pairs(autoInfo) do
            both = v
            method = 'get' .. str.ucfirst(k)
            bag[method] = function(this)
                return this[k]
            end
            if both then
                method = 'set' .. str.ucfirst(k)
                bag[method] = function(this, value)
                    this[k] = value
                    return this
                end
            end
        end
    end

    local mixins, mixinCtors = {}, {}

    self:mergeMixin(bag, mixins, mixinCtors)

    if bag.__dir then
        app.bagLookups[bag.__dir] = {path = bagPath, cls = bag.__cls}
    end

    local extendInfo, deferInfo, cacheInfo, runInfo =
        bag._ext_, bag.d__, bag.c__, bag._run_
    local diDefs = bag._diDefs_
    local getInfo, setInfo = bag._get_, bag._set_
    local cloneInfo = bag._clone_
    local bondInfo = bag._bond_
    local staticInfo = bag._static_
    local stackInfo = bag.t__

    if bag.s__ then
        for k, v in pairs(bag.s__) do
            staticInfo[k] = v
            if type(v) == 'function' then
                bag[k] = v
            end
        end
    end

    if stackInfo then
        for k, v in pairs(stackInfo) do
            stackInfo[k] = v
            if type(v) == 'function' then
                bag[k] = v
            end
        end
    end

    local privates = bag.__

    if privates then
        for k, v in pairs(privates) do
            if type(v) == 'function' then
                bag[k] = v
            end
        end
    end

    local mtList

    local superNick, superPath
 
    if extendInfo then
        local extendInfoType = type(extendInfo)
        if extendInfoType == 'string' then
            extendInfo = {from = extendInfo}
        elseif extendInfoType == 'table' then

        else 
            error('invalid extendInfo')
        end

        superNick, superPath = extendInfo.from, extendInfo.path
        if superNick and not superPath then
            local bindInfo = app:getBind(superNick)
            if bindInfo then
                superPath = bindInfo.bag
            else
                error('super("'..superNick..'") not bound for [' .. bagPath .. ']')
            end
        end
    end

    local superInfo, superStatic
    if superPath then
        superInfo = self:getClassBaseInfo(superPath)
        superStatic = superInfo.static
        if staticInfo then
            if not superStatic then
                error('super class ' .. superPath .. ' must define _static_.')
            end 
            for k, v in pairs(staticInfo) do
                superStatic[k] = v
            end
        end
        staticInfo = superStatic
    end

    local isAbstractCls = false

    local bondList, bondDefs = {}, {}
    if bag.a__ then
        isAbstractCls = true
        local defs = {}
        for k, v in pairs(bag.a__) do
            tapd(defs, k)
        end
        if not bondInfo then
            bondInfo = {def = defs}
        else
            if type(bondInfo) == 'string' then
                bondInfo = {from = bondInfo, def = defs}
            elseif type(bondInfo) == 'table' then
                bondInfo = {from = bondInfo.from, def = defs}
            end
        end
        bag._bond_ = bondInfo
    end

    if bondInfo then
        local typ = type(bondInfo)
        if typ == 'string' then
            tapd(bondList, bondInfo)
        elseif typ == 'table' then
            if #bondInfo > 0 then
                bondList = bondInfo
            else
                local bondFrom = bondInfo.from
                bondDefs = bondInfo.def
                typ = type(bondFrom)
                if typ == 'string' then
                    tapd(bondList, bondFrom)
                elseif typ == 'table' then
                    bondList = bondFrom
                end
            end
        end
    end

    if staticInfo then
        staticInfo.new = function()

        end
    end

    baseInfo.static = staticInfo
    baseInfo.stack = stackInfo
    baseInfo.defer = lf.neverEmpty(deferInfo)
    baseInfo.cache = lf.neverEmpty(cacheInfo)
    baseInfo.run = runInfo
    baseInfo.mixins = mixins
    baseInfo.mixinCtors = mixinCtors
    baseInfo.new, baseInfo.ctor, baseInfo.get, baseInfo.set = 
        bag.new, bag.ctor, getInfo, setInfo    
    baseInfo.superPath = superPath
    baseInfo.diDefs = diDefs
    baseInfo.clone = cloneInfo
    baseInfo.bonds, baseInfo.bondDefs = bondList, bondDefs
    baseInfo.bag = bag
    baseInfo.privates = lf.neverEmpty(privates)
    baseInfo.isAbstract = isAbstractCls

    if bag._init_ then
        bag._init_(baseInfo)
    end

    app.classBaseInfos[bagPath] = baseInfo

    return baseInfo
end

function _M:getClassInfo(bagPath)

    local app = App

    local classInfo = app.classes[bagPath]

    if classInfo then
        return classInfo
    else
        classInfo = {}
    end

    local baseInfo = app.classBaseInfos[bagPath] or self:getClassBaseInfo(bagPath)
 
    local deferInfo, mixinCtors, cacheInfo, runInfo, getInfo, setInfo =
        baseInfo.defer, baseInfo.mixinCtors or {}, baseInfo.cache, baseInfo.run,
        baseInfo.get, baseInfo.set
    local mixins = baseInfo.mixins

    local cloneInfo = baseInfo.clone

    local bagNew, bagCtor = baseInfo.new, baseInfo.ctor
    local bagBonds = baseInfo.bonds
    local bagPrivates = baseInfo.privates
    local stackInfo = baseInfo.stack

    local bag = baseInfo.bag
    local mtNeedNew
    local diDefs = baseInfo.diDefs
    local ctorList = {}
    local bondList = {}
    local privateList = {}
    local t, vt

    if bagPrivates then
        t = bagPrivates._clsPath
        if t then privateList[t] = bagPrivates end
    end

    if #bagBonds > 0 then
        for _, v in ipairs(bagBonds) do
            bondList[v] = v
        end
    end

    if bagCtor then tapd(ctorList, bagCtor) end
    if bagNew then mtNeedNew = bag end

    local super, superInfo

    local mtList = {bag}

    local superDefer, superMixins, superMixinCtors,superCache,
        superRun, superGet, superSet, superStack

    local superNew, superCtor
    local superBonds, superPrivates
    local lastBag = bag

    local superPath = baseInfo.superPath

    local notImpls = {}

    while superPath do

        superInfo = self:getClassBaseInfo(superPath)
        super = superInfo.bag
        notImpls = bondDefCheck(app, lastBag, super, notImpls)
        tapd(mtList, super)

        superDefer, superMixinCtors, superCache, superRun, superGet, superSet = 
            superInfo.defer, superInfo.mixinCtors, superInfo.cache, superInfo.run,
            superInfo.get, superInfo.set
        superMixins = superInfo.mixins
        superClone = superInfo.clone

        superNew, superCtor = superInfo.new, superInfo.ctor
        superBonds = superInfo.bonds
        superPrivates = superInfo.privates
        superStack = superInfo.stack

        if superPrivates then
            t = superPrivates._clsPath
            if t then privateList[t] = superPrivates end
        end

        if superDefer then
            vt = type(superDefer)
            if vt == 'table' then
                deferInfo = deferInfo or {}
                for k, v in pairs(superDefer) do
                    deferInfo[k] = v
                end
            elseif vt == 'function' then
                if not deferInfo then
                    deferInfo = superDefer
                end
            end
        end
 
        if superCache then
            cacheInfo = cacheInfo or {}
            for k, v in pairs(superCache) do
                cacheInfo[k] = v
            end
        end
         
        if #superMixins > 0 then
            for _, v in ipairs(superMixins) do
                tapd(mixins, v)
            end
        end

        if #superMixinCtors > 0 then
            for _, v in ipairs(superMixinCtors) do
                tapd(mixinCtors, v)
            end
        end

        if superCtor then tapd(ctorList, superCtor) end
        if superRun then runInfo = superRun end

        if superGet then
            if not getInfo then
                getInfo = superGet
            end
        end

        if superSet then
            if not setInfo then
                setInfo = superSet
            end
        end

        if superNew then
            if not bagNew then
                bagNew = superNew
            end
            mtNeedNew = super
        end
        
        if superStack then
            if not stackInfo then
                stackInfo = superStack
            end
        end

        if #superBonds > 0 then
            for _, v in pairs(superBonds) do
                bondList[v] = v
            end
        end

        superPath = superInfo.superPath
        lastBag = super
    end

    superPath = baseInfo.superPath

    if not superPath then
        if not baseInfo.isAbstract then
            bondDefCheck(app, bag)
        end
    else
        checkLastBagBondDef(bagPath, bag, notImpls)
    end

    local baseMt

    if #mtList == 1 then
        baseMt = {}
        for k, v in pairs(bag) do
            baseMt[k] = v
        end
    else
        baseMt = {}
        for _, mt in ipairs(mtList) do
            for k, v in pairs(mt) do
                if not baseMt[k] then
                    baseMt[k] = v
                end
            end
        end
    end

    local appendBonds = {}
    for k, v in pairs(bondList) do
        local related = app:getRelatedBonds(k)
        if related then
            for _, vv in ipairs(related) do
                tapd(appendBonds, vv)
            end
        end
    end

    if #appendBonds > 0 then
        for _, v in ipairs(appendBonds) do
            bondList[v] = v
        end
    end

    classInfo.defer, classInfo.cache, classInfo.run = 
        deferInfo, cacheInfo, runInfo
    classInfo.new, classInfo.ctor, classInfo.get, classInfo.set = 
        bagNew, bagCtor, getInfo, setInfo
    classInfo.bagPath = bagPath
    classInfo.superPath = superPath
    classInfo.diDefs = diDefs
    classInfo.ctorList = ctorList
    classInfo.mixinCtors = mixinCtors
    classInfo.clone = cloneInfo
    classInfo.bag = bag
    classInfo.mtList = mtList
    classInfo.mixins = mixins
    classInfo.bonds = bondList
    classInfo.stack = stackInfo
    classInfo.baseMt = baseMt
 
    local onClsLoad = baseMt._load_
    if onClsLoad then
        onClsLoad(classInfo)

        mtList = classInfo.mtList
        bondList = classInfo.bonds
        deferInfo = classInfo.defer
        cacheInfo = classInfo.cache
        getInfo = classInfo.get
        setInfo = classInfo.set
        cloneInfo = classInfo.clone
        runInfo = classInfo.run
        stackInfo = classInfo.stack
        baseMt = classInfo.baseMt
    end

    local fixInfo = baseMt._fix_

    if fixInfo then
        fixInfo(baseMt)
        baseMt.__fixed = function(this, key)
            return app.fixedClasses[baseMt.__cls][key]
        end
    else
        baseMt.__fixed = function(this, key)
            return 
        end
    end

    baseMt.__path           = bagPath
    baseMt.__is             = isInstanceOf
    baseMt.__has            = methodExists
    baseMt.__new            = makeNewSelf
    baseMt.__staticBak      = baseInfo.static
    baseMt.__stackBak       = baseInfo.stack
    baseMt.__static         = useObjStatic
    baseMt.__clone          = makeClone
    baseMt.__mtList         = mtList
    baseMt.__bonds          = bondList
    baseMt.__cloneCb        = cloneInfo
    baseMt.__baseMt         = baseMt
    baseMt.__get            = getInfo
    baseMt.__set            = setInfo
    baseMt.__cache          = cacheInfo
    baseMt.__defer          = deferInfo
    baseMt.__run            = runInfo
    baseMt.__do             = objInvokeMethod
    baseMt.__priList        = privateList
    baseMt.__mixins         = mixins

    if superPath or deferInfo or cacheInfo or runInfo
        or getInfo or setInfo or baseMt.c__ then

        baseMt.__super     = runSuperMethod

        classInfo.needExtend = true
        if cacheInfo then
            self:makeCacheInfo(baseMt, cacheInfo)
        end

        local objMt = self:makeObjMt(baseMt, deferInfo, runInfo, getInfo, setInfo)

        objMt.__call = baseMt.__call
         
        classInfo.objMt = objMt
    else

    end

    app.classes[bagPath] = classInfo

    return classInfo
end

function _M.isInstanceOf(subject, clsType)

    return isInstanceOf(subject, clsType)
end

function _M:makeCacheInfo(baseMt, cacheInfo)

    for key, item in pairs(cacheInfo) do
        baseMt[key] = function(this)
            local t = this._cached_[key]
            if type(t) == 'nil' then
                t = item(this)
                this._cached_[key] = t
            end
            return t
        end
    end
end

function _M:makeObjMt(baseMt, defer, run, get, set)

    local app = App
     
    local mt = { __index = function(this, key)
        return extendMtTable(this, app, defer, run, get, baseMt, key)
    end}

    if set then
        mt.__newindex = function(obj, key, value)
            return extendNewindex(obj, set, key, value)
        end
    end

    return mt
end

function _M:getStaticObj(cls, nick)

    local app = App
    local obj = app.staticObjs[cls]

    if obj then
        return obj
    end

    local clsInfo = app:getClsInfo(cls)
    if not clsInfo then
        error(cls .. ' not bound yet')
    end

    local baseMt = clsInfo.baseMt

    local static = baseMt.__staticBak

    obj = {__cls = cls, __nick = nick}
    if static then
        obj.static = static
    end
    local stack = baseMt.__stackBak
    if stack then
        for k, v in pairs(stack) do
            obj[k] = function(...)
                
                return v(obj, ...)
            end
        end
    end

    setmetatable(obj, {__index = baseMt})

    app.staticObjs[cls] = obj

    return obj
end

return _M

