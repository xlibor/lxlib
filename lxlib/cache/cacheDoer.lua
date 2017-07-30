
local lx, _M, mt = oo{
    _cls_ = '',
}

local app, lf, tb, str, new = lx.kit()
local throw = lx.throw
local packer

function _M._init_()

    packer = new('msgPack')
end

function _M:new(store, config)

    local this = {
        store = store,
        config = config,
        default = 60
    }
    
    return oo(this, mt)
end

function _M:ctor()

    self:loadConfig(self.store, self.config)
end

function _M.__:loadConfig(store, config)

    local mainConfig = app:conf('cache')

    local enable = mainConfig.enable or false
    local mainLock = mainConfig.lock or {}
    local currLock = config.lock or {}
    local lockInfo = tb.merge(mainLock, currLock)

    local autoLock = lockInfo.auto or false
    local shdict = lockInfo.shdict or 'lxCache'
    local prefix = (config.prefix or mainConfig.prefix) or ''
    local pttl = lockInfo.pttl or 10
    local nttl = lockInfo.nttl or 3
    
    self.enable = enable
    self.autoLock = autoLock
    self.prefix = prefix
    self.shdict = shdict
    self.pttl = pttl
    self.nttl = nttl

end

function _M:has(key)

    return lf.isset(self:get(key, true))
end

function _M:get(key, cancelUnpack)

    local value, fromCache

    if self.autoLock then
        local lock = app:make('cache.lock', function()
            
            return self:runGet(key)
        end, self)

        value, fromCache = lock:load(self:warpKey(key))
        if value and fromCache then
            self:fireCacheEvent('hited', {key, value})
        end
    else
        value = self:runGet(key)
    end

    if value and not cancelUnpack then
        value = self:unpackValue(value)
    end

    return value
end

function _M:runGet(key)

    if lf.isTbl(key) then
        return self:many(key)
    end

    local wk = self:warpKey(key)

    local value, forgot = self.store:get(wk)

    if not value then
        self:fireCacheEvent('missed', {key})
        if forgot then
            self:syncDelete(wk)
        end
    else
        self:fireCacheEvent('hit', {key, value})
    end

    return value
end

function _M:many(keys)

    local normalizedKeys = {}

    for key, value in pairs(keys) do
        tapd(normalizedKeys, lf.isStr(key) and key or value)
    end

    local values = self.store:many(normalizedKeys)

    for key, value in pairs(values) do
        if not value then
            self:fireCacheEvent('missed', {key})

            value = lf.isset(keys[key]) and value(keys[key])
        else 
            self:fireCacheEvent('hit', {key, value})
        end
    end

    return values
end

function _M:pull(key)

    local value = self:get(key)

    self:forget(key)

    return value
end

function _M:put(key, value, seconds)

    if lf.isTbl(key) then
        return self:putMany(key, value)
    end

    seconds = self:getSeconds(seconds)

    if seconds then
        local wk = self:warpKey(key)
        local packedValue = self:packValue(value)

        if self.store:put(wk, packedValue, seconds) then
            self:syncPut(wk, packedValue)
        end
        self:fireCacheEvent('write', {key, value, seconds})
    end
end

function _M:update(key, value)

    local wk = self:warpKey(key)
    local packedValue = self:packValue(value)

    if self.store:update(wk, packedValue) then
        self:syncPut(wk, packedValue)
        self:fireCacheEvent('update', {key, value, seconds})
    end
end

function _M:packValue(value)

    return packer:pack(value)
end

function _M:unpackValue(value)

    return packer:unpack(value)
end

function _M:syncPut(key, value, seconds)

    if self.autoLock then
        local shd = self:getShd()
        local ok, err = shd:replace(key, value, 10)
        if not ok then
            shd:add(key, value, 10)
        end
    end

end

function _M:syncDelete(key)

    if self.autoLock then
        local shd = self:getShd()
        shd:delete(key)
    end
end

function _M:putMany(values, seconds)

    seconds = self:getSeconds(seconds)

    if seconds then
        self.store:putMany(values, seconds)

        for key, value in pairs(values) do 
            self:fireCacheEvent('write', {key, value, seconds})
        end
    end
end

function _M:add(key, value, seconds)

    seconds = self:getSeconds(seconds)

    if not seconds then
        return false
    end

    local packedValue = self:packValue(value)

    if self.store:__has('add') then
        return self.store:add(self:warpKey(key), packedValue, seconds)
    end

    if not self:get(key) then
        self:put(key, packedValue, seconds)

        return true
    end

    return false
end

function _M:increment(key, value)

    value = value or 1
    local wk = self:warpKey(key)
    local current, forgot = self.store:get(wk)
    if not current then
        if forgot then
            self:syncDelete(wk)
        end
        return
    end

    current = self:unpackValue(current)
    local newValue = current + value

    self:update(key, newValue)
end

_M.incr = _M.increment

function _M:decrement(key, value)

    value = value or 1
    local wk = self:warpKey(key)
    local current, forgot = self.store:get(wk)
    if not current then
        if forgot then
            self:syncDelete(wk)
        end
        return 
    end
    
    current = self:unpackValue(current)
    local newValue = current - value

    self:update(key, newValue)
end

_M.decr = _M.decrement

function _M:forever(key, value)

    local packedValue = self:packValue(value)

    self.store:forever(self:warpKey(key), packedValue)

    self:fireCacheEvent('write', {key, value, 0})
end

function _M:remember(key, seconds, callback)

    if not self.enable then
        return callback()
    end

    value = self:get(key)

    if value then
        return value
    end

    value = callback()
    self:put(key, value, seconds)

    return value
end

function _M:rememberForever(key, callback)

    if not self.enable then
        return callback()
    end
    
    local value = self:get(key)
    if value then
        return value
    end

    value = callback()

    self:forever(key, value)

    return value
end

_M.sear = _M.rememberForever

function _M:forget(key)

    local wk = self:warpKey(key)
    local success = self.store:forget(wk)
    self:syncDelete(wk)
    self:fireCacheEvent('delete', {key})

    return success
end

function _M:tags(...)

    local names = lf.needArgs(...)
    local taggedCache = new(
        'cache.taggedDoer', self.store, self.config,
        new('cache.tagSet', self:getShd(), names)
    )

    return taggedCache
end

function _M.__:warpKey(key)

    return self.prefix .. key
end

function _M:getDefaultCacheTime()

    return self.default
end

function _M:setDefaultCacheTime(seconds)

    self.default = seconds
end

function _M:getStore()

    return self.store
end

function _M:getShd()

    local shd = ngx.shared[self.shdict]

    return shd
end

function _M:setEventDispatcher(events)

    self.events = events
end

function _M.__:fireCacheEvent(event, payload)

    if not self.events then
        return
    end

    if event == 'hit' then
        if tb.count(payload) == 2 then
            tapd(payload, {})
        end

        return self.events:fire('cacheHit', payload[1], payload[2], payload[3])
    elseif event == 'missed' then
        if tb.count(payload) == 1 then
            tapd(payload, {})
        end

        return self.events:fire('cacheMissed', payload[1], payload[2])
    elseif event == 'delete' then
        if (count(payload) == 1) then
            tapd(payload, {})
        end

        return self.events:fire('keyForgotten', payload[1], payload[2])
    elseif event == 'write' then
        if (tb.count(payload) == 3) then
            tapd(payload, {})
        end

        return self.events:fire('keyWritten', payload[1], payload[2], payload[3], payload[4])
    end
end

function _M.__:getSeconds(duration)

    return duration or self.default
end

function _M:_run_(method)

    return 'getStore'
end

function _M:_clone_(nweObj)

    nweObj.store = self.store:__clone()
end

return _M

