
local lx, _M, mt = oo{
    _cls_ = '',
    _static_ = {}
}

local app, lf, tb, str = lx.kit()
local trim = str.trim

function _M:new(attrs)

    local prefix, namespace, domain, bar, key, as, where = 
        attrs.pre or attrs.prefix, attrs.ns or attrs.namespace,
        attrs.domain, attrs.bar, attrs.key, attrs.as, attrs.where

    prefix = prefix or '/'
    
    prefix = str.neat(prefix, '/')

    local this = {
        key = key,
        prefix = prefix,
        as = as,
        bar = bar,
        res = '',
        namespace = namespace,
        domain = domain,
        where = where or {}
    }

    oo(this, mt)

    return this
end

local function formatNamespace(new, old)

    local ret
    if new then
        ret = old and old .. '.' .. new or new
    else
        ret = old
    end

    return ret
end

local function formatPrefix(new, old)

    local ret
    if new then
        if old then
            ret = trim(old, '/') .. '/' .. trim(new, '/')
        else
            ret = new
        end
    else
        ret = old
    end

    return ret
end

local function formatAlias(new, old)

    local ret

    if new then
        ret = old and old .. new or new
    else
        ret = old
    end
 
    return ret
end

local function mergeBar(new, old)

    local oldType = type(old)
    if oldType == 'string' then
        old = {old}
    end
    local newType = type(new)
    if newType == 'string' then
        new = {new}
    end

    if not old then old = {} end
    if not new then new = {} end

    local lookup
    if #new > 0 then
        lookup = tb.flip(new, true)
    else
        lookup = {}
    end

    for k, v in ipairs(old) do
        if not lookup[v] then
            tapd(new, v)
            lookup[v] = v
        end
    end
    
    return new
end

local function mergeWhere(new, old)

    if not old then old = {} end
    if not new then new = {} end

    for k, v in pairs(old) do
        if not new[k] then
            new[k] = v
        end
    end

    return new
end

function _M:mergeWith(old)

    self.namespace = formatNamespace(self.namespace, old.namespace)
    self.prefix = formatPrefix(self.prefix, old.prefix)
    self.as = formatAlias(self.as, old.as)
    self.bar = mergeBar(self.bar, old.bar)
    self.where = mergeWhere(self.where, old.where)
end

function _M:mergeInto(route)
    
    local action = route.action
    action.namespace = formatNamespace(action.namespace, self.namespace)
    action.prefix = formatPrefix(action.prefix, self.prefix)
    action.as = formatAlias(action.as, self.as)
    action.bar = mergeBar(action.bar, self.bar)
    action.where = mergeWhere(action.where, self.where)
    route:setPrefix(action.prefix)
    route:setNamespace(action.namespace)
end

function _M.s__.merge(new, old)

    new.namespace = formatNamespace(new.namespace, old.namespace)
    new.prefix = formatPrefix(new.prefix, old.prefix)
    new.as = formatAlias(new.as, old.as)
    new.bar = mergeBar(new.bar, old.bar)
    new.where = mergeWhere(new.where, old.where)

    return new
end

return _M

