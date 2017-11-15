
local lx, _M, mt = oo{ 
    _cls_ = '',
    _bond_ = 'sessionBond'
}

local metadataBase = require('lxlib.session.metadata')
local app, lf, tb, str, new = lx.kit()
local cookieHandler = 'lxlib.session.handler.cookieHandler'

local packer

function _M._init_()

    packer = new('msgPack')
end

function _M:new(name, handler, id)

    local this = {
        name = name,
        handler = handler,
        attrs = {},
        items = {},
        metaItem = metadataBase:new('_lx_meta', 0),
        itemData = {},
        started = false
    }

    oo(this, mt)
    this:setId(id)

    return this
end

function _M:start()

    self:loadSession()

    if not self:has('_token') then
        self:regenToken()
    end

    self.started = true

    return true
end

function _M:loadSession()

    self.attrs = tb.merge(self.attrs, self:readFromHandler())
    local items = tb.mergeList(self.items, {self.metaItem})
    for _, item in ipairs(items) do
        self:initLocalItem(item)
        item:init(self.itemData[item.storeKey])
    end

end

function _M:initLocalItem(item)

    local storeKey = item:getStoreKey()
    self.itemData[storeKey] = self:pull(storeKey, {})
end

function _M:readFromHandler()

    local data = self.handler:read(self.id)
    if data then
        data = packer:unpack(data)
        if type(data) == 'table' then
            return data
        end
    end

    return {}
end

function _M:getId()
    
    return self.id
end

function _M:setId(id)

    if id then
        self.id = id
    else
        self.id = self:generateId()
    end
end

function _M:generateId()

    return lf.guid()
end
 
function _M:invalidate()

    self:clear()

    return self:migrate(true)
end

function _M:migrate(destroy)

    if destroy then
        self.handler:destroy(self.id)
    end
    self:setExists(false)
    self.id = self:generateId()

    return true
end

function _M:regenerate(destroy)

    return self:migrate(destroy)
end

_M.regen = _M.regenerate

function _M:save()

    self:addItemDataToSession()
    self:ageFlashData()
    local t = packer:pack(self.attrs)
    self.handler:write(self.id, t)

    self.started = false
end

function _M:addItemDataToSession()

    local items = tb.mergeList(self.items, {self.metaItem})
    local key, data
    for _, item in ipairs(items) do
        key = item.storeKey
        data = self.itemData[key]
        if data then
            self:put(key, data)
        end
    end
end

function _M:ageFlashData()

    self:forget(self:get('flash.old',{}))
    self:put('flash.old', self:get('flash.new',{}))
    self:put('flash.new', {})
end

function _M:get(name, default)

    return tb.get(self.attrs, name, default)
end

function _M:set(name, value)
 
    tb.set(self.attrs, name, value)
end

function _M:has(name)
    
    local t = self:get(name)

    return lf.isset(t)
end

function _M:pull(key, default)

    return tb.pull(self.attrs, key, default)
end

function _M:put(key, value)

    local kvs = {}
    if type(key) == 'string' then
        kvs[key] = value
    else
        kvs = key
    end

    for k, v in pairs(kvs) do
        self:set(k, v)
    end
end

function _M:push(key, value)

    local t = self:get(key, {})
    t[#t + 1] = value
    self:put(key, t)
end

function _M:hasOldInput(key)

    local old = self:getOldInput(key)
    if not key then
        if #old > 0 then return true end
    else
        if old then return true end
    end
end

function _M:getOldInput(key, default)

    local input = self:get('_old_input', {})

    local t = tb.get(input, key, default)

    return t
end

function _M:flash(key, value)

    self:put(key, value)
    self:push('flash.new', key)
    self:removeFromOldFlashData({key})
end

function _M:now(key, value)

    self:put(key, value)
    self:push('flash.old', key)
end

function _M:flashInput(value)

    self:flash('_old_input', value)
end

function _M:reflash()

    self:mergeNewFlashes(self:get('flash.old', {}))
    self:put('flash.old', {})
end

function _M:keep(...)

    local keys
    local args = {...}
    local p1 = args[1]
 
    if type(p1) == 'table' then
        keys = p1
    else
        keys = args
    end

    self:mergeNewFlashes(keys)
    self:removeFromOldFlashData(keys)
end

function _M:mergeNewFlashes(keys)

    local flashNew = self:get('flash.new', {})
    local values = tb.unique(tb.merge(flashNew, keys))
    self:put('flash.new', values)
end

function _M:removeFromOldFlashData(keys)

    self:put('flash.old', tb.diff(self:get('flash.old', {}), keys))

end

function _M:all()

    return self.attrs
end

function _M:replace(attrs)

    self:put(attrs)
end

function _M:remove(name)

    tb.pull(self.attrs, name)
end

function _M:forget(keys)

    tb.forget(self.attrs, keys)
end

function _M:clear()

    self.attrs = {}

    for _, item in ipairs(self.items) do
        item:clear()
    end
end

function _M:flush()

    self:clear()
end

function _M:isStarted()

    return self.started
end

function _M:regItem(item)

    self.items[item.storeKey] = item
end

function _M:getItem(name)

    return tb.get(self.items, name)
end

function _M:getMetaItem()

    return self.metaItem
end

function _M:getItemData(name)

    return tb.get(self.itemData, name, {})
end

function _M:token()

    return self:get('_token')
end

function _M:getToken()

    return self:token()
end

function _M:regenToken()

    self:put('_token', lf.guid())
end

function _M:previousUrl()

    return self:get('_previous.url')
end

function _M:setPreviousUrl(url)

    return self:put('_previous.url', url)

end

function _M:setExists(value)

    if self.handler.setExists then
        self.handler:setExists(value)
    end
end

function _M:getHandler()

    return self.handler
end

function _M:handlerNeedsRequest()

    if self.handler:__is(cookieHandler) then
        
        return true
    end
end

function _M:setRequestOnHandler(req)

    if self:handlerNeedsRequest() then
        self.handler:setRequest(req)
    end
end

return _M


