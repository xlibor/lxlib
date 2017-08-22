
local _M = {
    _cls_ = ''
}
local mt = { __index = _M }

local lx = require('lxlib')
local lf, tb, str = lx.f, lx.tb, lx.str

local objectBase = require('lxlib.core.object')
local bondBase = require('lxlib.core.bond')

function _M:new()
    
    local this = {
        binds = {},
        bonds = {},
        bindBonds = {},
        bondParents = {},
        instances = {},
        classes = {},
        classBaseInfos = {},
        staticObjs = {},
        resolvingCallbacks = {},
        reboundCallbacks = {},
        fixedClasses = {}
    }

    this.objCtor = objectBase:new(this)
    setmetatable(this, mt)

    return this
end

function _M:fix(cls, nick, fixTo)

    tb.set(self.fixedClasses, cls.__cls, nick, fixTo)
end

function _M:take()

end

function _M:bind(nick, bagInfo, concrete, shared, sharedInCtx)

    local bag
    local typ = type(bagInfo)

    if typ == 'string' then
        bag = bagInfo
        if type(concrete) == 'function' then
            self.binds[bag] = {
                bag = bag
            }
        end
    elseif typ == 'table' then
        if #bagInfo > 0 then

        else
            error('bagInfo is empty')
        end
    elseif typ == 'function' then

        concrete = bagInfo
    elseif typ == 'nil' then
        if nick then
            bag = nick
        else
            error('bind nothing')
        end
    end

    self.binds[nick] = {
        nick = nick, bag = bag, concrete = concrete, 
        shared = shared, sharedInCtx = sharedInCtx
    }

end

function _M:bound(nick)

    local obj = self.binds[nick] or self.instances[nick]

    return obj and true or false
end

function _M:need(bag)
    
    self:bind(bag, bag)
end

function _M:make(nick, ...)

    local obj, t

    local vt = type(nick)
    if vt == 'string' then
    elseif vt == 'table' then
        t = rawget(nick, '__nick')
        nick = t or nick.__cls
    else
        error('invalid nick type:' .. vt)
    end

    obj = self.instances[nick]
    if obj then
        return obj
    end

    local bind = self:getBind(nick)
    if not bind then
        error(nick .. ' not bound.')
    end

    local sharedInCtx = bind.sharedInCtx

    if sharedInCtx then
        obj = self:getInstanceInCtx(nick)
        if obj then
            return obj
        end
    end

    obj = self:build(nick, bind, nil, ...)

    return self:afterMake(obj, nick, bind)
end

function _M:afterMake(obj, nick, bind)

    rawset(obj, '__nick', nick)

    if self:isShared(nick) then
        self.instances[nick] = obj
        self[nick] = obj
    end

    if bind.sharedInCtx then
        self:setInstanceToCtx(nick, obj)
    end

    self:fireResolvingCallbacks(nick, obj)

    return obj
end

function _M:cancelShare(...)

    local nicks = lf.needArgs(...)

    for i, nick in ipairs(nicks) do
        local bind = self.binds[nick]
        bind.shared = false
        bind.sharedInCtx = false

        self.instances[nick] = nil
    end

end

function _M:fireResolvingCallbacks(nick, obj)

    local callbacks = self.resolvingCallbacks[nick]

    if callbacks then

        for _, callback in ipairs(callbacks) do
            callback(obj)
        end
    end
end

function _M:makeWith(nick, superObj, ...)

    local instance = self.instances[nick]
    if instance then
        return instance
    end

    local bind = self:getBind(nick)
    if not bind then
        error(nick .. ' no bind info.')
    end

    local obj = self:build(nick, bind, superObj, ...)

    return self:afterMake(obj, nick, bind)
end

function _M:create(nick, bagPath, superObj, ...)

    return self.objCtor:create(nick, bagPath, superObj, ...)
end

function _M:build(nick, bind, superObj, ...)

    local obj
    local bag, concrete = bind.bag, bind.concrete
    local typ = type(concrete)

    if typ == 'function' then
        obj = concrete(...)
    elseif typ == 'string' then
        if str.len(concrete) > 0 then
            local method = concrete
            local base = require(bag)
            obj = base[method](base, ...)
        else
            obj = require(bag)
        end
    elseif typ == 'nil' then
        local method = concrete
        obj = self:create(nick, bag, superObj, ...)
    else
        error('concrete is not support')
    end

    return obj
end

function _M:bond(key, bond)
    
    self.bindBonds[key] = bond
end

function _M:getBond(key)

    local bond = self.bonds[key]

    if not bond then
        local bind = self.bindBonds[key]
        if not bind then
            error('invalid bond:' .. key)
        end

        bondBase.setBond(self, key, bind)
        bond = self.bonds[key]
        if not bond then
            error('failed to get bond:' .. key)
        end
    end

    return bond
end

function _M:getRelatedBonds(key)

    local ret
    local bonds = self.bondParents
    local t = bonds[key]

    while t do
        if not ret then
            ret = {}
        end
        tapd(ret, t)
        t = bonds[t]
    end

    return ret
end

function _M:initCoreBonds()

    local bonds = lf.import('lxlib.core.bond.coreBonds')

    local methods
    for k, v in pairs(bonds) do
        if type(v) == 'table' then
            methods = {}
            for kk, vv in pairs(v) do
                if type(vv) == 'function' then
                    methods[kk] = kk
                end
            end
            self.bonds[k] = methods
        end
    end

    self:bond('throwable', 'lxlib.exception.bond.throwable')
end

function _M:instance(nick, instance)

    self.instances[nick] = instance
end

function _M:getBag(nick)

    local bind = self.binds[nick]

    if bind then
        return bind.bag
    end
end

function _M:isShared(nick)

    if self.instances[nick] then return true end
    if self.binds[nick].shared then return true end

    return false
end

function _M:getBind(nick)

    return self.binds[nick]
end

function _M:getConcrete(nick)

    local concrete
    local bind = self.binds[nick]
    if bind then
        concrete = bind.concrete
    else
        error('this bag not bound')
    end

    return concrete
end

function _M:get(key)

    local obj = self:make(key)

    return obj
end

function _M:set(key, value)

    self:bind(key, value)
end

function _M:share(cb)

    return function()
        cb()
    end
end

function _M:single(nick, bag, concrete)

    self:bind(nick, bag, concrete, true)
end

function _M:keep(nick, bag, concrete)

    self:bind(nick, bag, concrete, false, true)
end

function _M:resolving(nick, callback)

    tb.mapd(self.resolvingCallbacks, nick, callback)
end

function _M:refresh(nick, target, method)

    self:rebinding(nick, function(instance)
        
        local fn = target[method]
        if fn then
            fn(target, instance)
        end
    end)
end

function _M:rebinding(nick, callback, remake)

    tb.mapd(self.reboundCallbacks, nick, callback)

    if self:bound(nick) and remake then
        return self:make(nick)
    end
end

function _M:getReboundCallbacks(nick)

    local t = self.reboundCallbacks(nick)
    if t then
        return
    end

    return {}
end

function _M:hasClass(cls)

    local bind = self:getBind(cls)
    
    return bind and true or false
end

function _M:hasBond(bond)
 
    return self.bonds[bond] and true or false
end

function _M:getClsInfo(cls)

    local bagPath = cls
    local bind = self:getBind(cls)
    if bind then
        bagPath = bind.bag or cls
    end

    local oc = self.objCtor

    return oc:getClassInfo(bagPath)
end

function _M:use(cls)

    local bagPath, isNick = self:getBagPath(cls)
    local oc = self.objCtor

    return oc:getStaticObj(bagPath, isNick and cls or false)
end

function _M:getBagPath(nick)

    local isNick = false
    local bagPath = nick
    local bind = self:getBind(nick)
    if bind then
        bagPath = bind.bag or nick
        isNick = true
    end

    return bagPath, isNick
end

function _M:getClsBaseInfo(cls)

    local bagPath = self:getBagPath(cls)

    local oc = self.objCtor

    return oc:getClassBaseInfo(bagPath)
end

function _M:getBaseMt(cls)

    local clsInfo = self:getClsInfo(cls)
    if clsInfo then

        return setmetatable({}, {__index = clsInfo.baseMt})
    end
end

function _M:isSubClsOf(cls, parent)

    local bindInfo = self.binds[parent]
    if bindInfo then
        parent = bindInfo.bag
    end

    local baseMt = self:getBaseMt(cls)
    if baseMt then
        local mtList = baseMt.__mtList
        for _, mt in ipairs(mtList) do
            if parent == mt.__cls then
                return true
            end
        end
    else
        error('invalid bag [' .. cls .. ']')
    end

    return false
end

function _M:methodExists(cls, method)

    local baseMt, obj

    if lf.isObj(cls) then
        obj = cls
        baseMt = obj.__baseMt
        if baseMt[method] then
            return true
        end
    else
        local clsInfo = self:getClsInfo(cls)
        if clsInfo then
            baseMt = clsInfo.baseMt
            if baseMt[method] then
                return true
            end
        end
    end

    return false
end

return _M

