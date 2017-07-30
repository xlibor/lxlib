
local _M = {
    _cls_ = '@col',
    _bond_ = {
        'countable', 'eachable', 'jsonable', 'strable', 'packable'
    },
    __    = {}
}

local mt = { __index = _M }

local json = require('lxlib.json.base')
local lf = require('lxlib.base.pub')
local Str = require('lxlib.base.str')
local utils = require('lxlib.base.utils')
local Arr
local sfind, slower = string.find, string.lower
local tinsert, tremove, tsort = table.insert, table.remove, table.sort
local cstr = tostring
local cachedChainKeys = {}
local colBonds

local function checkArr()

    if not Arr then
        Arr = require('lxlib.base.arr')
    end
end

function _M:init(...)
    
    checkArr()

    local asDict = true
    local args = {...}
    local argsLen = #args

    if argsLen == 0 then
        return self
    end

    if self.asList then
        asDict = false
        self.asDict = false
    end

    local scData = {}
    local p1 = args[1]
    local p1Type = type(p1)
    local k, v

    if p1Type == 'table' then
        scData = p1
        if #scData > 0  then
            if asDict then
                self:initFrom(scData)
            else
                self:initFrom(scData, true)
            end
        else
            self:initFrom(scData)
        end
    else
        if asDict then 
            if math.mod(argsLen, 2) == 0 then
                for i = 1, argsLen, 2 do
                    k = args[i]; v = args[i+1]
                    if type(k) ~= 'string' then k = tostring(k) end
                    self:add(v, k)
                end
            end
        else
            self.items = args
        end
    end

    return self
end

function _M:new()

    local this = {
        __cls = 'col',
        items = {},
        _keys = {},
        isLcase = false,
        item = {},
        itemName = false,
        default = nil,
        asDict = true,
        asList = false,
        jsonOrder = false,
        chainGetable = false,
        chainSetable = false,
        autoDerive    = false,
        chainSeparator = '.',
    }
    
    setmetatable(this, mt)
 
    return this
end

function _M:final(tbl, ...)

    local args, len = lf.getArgs(...)

    local autoDerive = self.autoDerive
    if autoDerive then
        local asList = false
        local keys

        if len > 0 then
            asList = args[1]
            if asList == 0 then
                asList = #tbl > 0
            end
            keys = args[2]
        else
            asList = self.asList
        end

        local col = self:new()

        if asList then
            col:useList()
        else
            col:useDict()
        end

        col:init(tbl)
        col.autoDerive = true
        if keys then
            col._keys = keys
        end

        return col
    else
        return tbl
    end
end

function _M:ad()

    self.autoDerive = true
    return self
end

function _M:make(items, ...)

    local args, len = lf.getArgs(...)

    items = items or {}
    if items.__cls == 'col' then
        items = items:all()
    end
    local asList = false
    if len == 0 then
        asList = #items > 0
    else
        asList = args[1]
    end

    local col
    if asList then
        col = self:new():useList(items)
    else
        col = self:new():useDict(items)
    end
    col.autoDerive = self.autoDerive

    return col
end

function _M:values()

    return self:final(Arr.values(self.items), true)
end

function _M:keys()

    if self.asDict then
        return self:final(self._keys, true)
    else
        return self:final(Arr.keys(self.items), true)
    end
end

function _M:itemable(itemName)

    itemName = itemName or 'item'
    self.itemName = itemName
    self[itemName] = { __col = self }
    setmetatable(self[itemName] , self:getItemMt())

    return self
end

function _M:dotable(config)

    local getable, setable, separator
    if config then
        getable, setable, separator = config.get, config.set, config.sign
    else
        getable, setable = true, true
    end

    self.chainGetable = getable
    self.chainSetable = setable
 
    if separator then
        self.chainSeparator = separator
    end

    return self
end

function _M:__is(bond)

    if not colBonds then
        local baseBonds = Arr.clone(_M._bond_)
        tapd(baseBonds, 'col')
        colBonds = Arr.flip(baseBonds, true)
    end

    local vt = type(bond)

    if vt == 'string' then
        return colBonds[bond] and true or false
    else
        error('invalid bondType')
    end
end

function _M:conf(config)

    local itemable, joable, lcase, dotable = 
        config.itemable, config.joable, config.lcase, config.dotable

    if itemable then 
        self:itemable()
    end

    if type(joable) == 'boolean' or joable then
        self.jsonOrder = joable
    end

    if type(lcase) == 'boolean' or lcase then
        self.isLcase = lcase
    end

    if dotable then 
        local typ = type(dotable)
        if typ == 'boolean' then
            self.chainGetable = true
            self.chainSetable = false
        elseif typ == 'table' then
            self:dotable(dotable)
        end
    end

    return self
end

function _M:useDict(dict)

    self.asDict = true
    self.asList = false
    if dict then
        self:init(dict)
    end

    return self
end

function _M:useList(list)

    self.asDict = false
    self.asList = true
    if list then
        self:init(list)
    end

    return self
end

local function myIter_ikv(self, cur)

    local k, v
    local ks, vs = self._keys, self.items
    if not cur then return end
     
    step = step or 1
 
    cur = cur + step
    k = ks[cur]
    v = vs[k]
    if k then 
        return cur, k, v
    else
        return nil
    end
end

local function myIter_kvi(self, conf)

    local k, v
    local ks, vs = self._keys, self.items
 
    local step, cur = conf.step, conf.begin

    return function()
        cur = cur + step
        k = ks[cur]
        v = vs[k]
        if k then
            return k, v, cur
        else
            return nil
        end
    end
end

local function myIter_v(self, conf)
    
    local k, v
    local ks, vs = self._keys, self.items

    local step, cur = conf.step, conf.begin

    return function()
        cur = cur + step
        k = ks[cur]
        v = vs[k]
        if k then 
            return v
        else
            return nil
        end
    end
end

local function myIterList_v(self, conf)

    local k, v
    local vs = self.items

    local step, cur = conf.step, conf.begin

    return function()
        cur = cur + step
        v = vs[cur]
        if v then 
            return v
        else
            return nil
        end
    end
end

local function getIterConf(self, reverse, step)

    local begin = 0
    step = step or 1
    reverse = reverse or false
    if reverse then 
        begin = #self._keys + 1
        step = - step
    end
    local conf = {step = step, begin = begin}

    return conf
end

function _M:ikv(reverse, step)

    if self.asDict then
        local conf = getIterConf(self, reverse, step)
        return lf.use(conf, myIter_ikv), self, begin
    end
end

function _M:kvi(reverse, step)

    if self.asDict then
        local conf = getIterConf(self, reverse, step)
        return myIter_kvi(self, conf)
    end
end

function _M:kv(reverse, step)

    local conf = getIterConf(self, reverse, step)
    return myIter_kvi(self, conf)

end

function _M:v(reverse, step)

    local conf = getIterConf(self, reverse, step)

    if self.asDict then
        return myIter_v(self, conf)
    else
        return myIterList_v(self, conf)
    end
end

function _M:toEach()

    return pairs(self.items)
end

function _M:allNodesMtlize()

    local vs = self.items
    local jsontype = 'object'
    local eType, eVs
    local jsonmt 

    if self.asDict then 
        for k, e in pairs(vs) do
            eType = type(e)
            if eType == 'table' then
                if e.__cls == 'col' then
                    e:allNodesMtlize()
                    vs[k] = e.items
                end
            end
        end

        jsonmt = { __jsontype = 'object' }
        if self.jsonOrder then
            jsonmt.__jsonorder = self._keys
        end
        setmetatable(vs, jsonmt)
    end

    if self.asList then 
        for i, e in ipairs(vs) do
            eType = type(e)
            if eType == 'table' then
                if e.__cls == 'col' then
                    e:allNodesMtlize()
                    vs[i] = e.items
                end
            end
        end

        jsonmt = { __jsontype = 'array' }
        setmetatable(vs, jsonmt)
    end

end

function _M:toJson(useKeyOrder, indent)
    
    local vs = self.items
    if not json.orderable then
        return json.encode(vs)
    end

    if useKeyOrder then self.jsonOrder = true end

    self:allNodesMtlize()

    if indent then
        return json.encode(vs, {indent = true })
    else
        return json.encode(vs)
    end
end

function _M:toArr()

    return self:all()
end

function _M:toStr()

    return self:toJson()
end

function _M:pack(packer)

    local obj = Arr.copyScalar(self)
    obj.items = self.items
    obj._keys = self._keys

    return obj
end

function _M:unpack(data)

    for k, v in pairs(data) do
        self[k] = v
    end
    if self.itemName then
        self:itemable(self.itemName)
    end
end

function _M:getItemMt()

    local itemMt = {
        __index = function(tbl, key)
            return self:get(key)
        end,
        __newindex = function(tbl, key, value)
            self:set(key, value)
        end,
        __call = function(tbl,...)
            local items = {}
            local args = {...}
            local argLen = #args
            local firstArgType = type(args[1])
             
            if argLen == 1 and firstArgType == 'table' then
                local items = args[1]
                local t
                for k, v in pairs(items) do
                    t = self:get(k, v)
                    if type(t) ~= 'nil' then items[k] = t end
                end
                return items
            else 
                for i, k in ipairs(args) do
                    items[i] = self:get(k)
                end
                return unpack(items)
            end
        end
    }
    
    return itemMt
end

function _M:useLcase(ifUse)

    if ifUse then
        self.isLcase = true
    else
        self.isLcase = false
    end

    return self
end

function _M:setDefault(defaultValue)
    
    self.default = defaultValue
end

function _M:add(item, key, before, after)
    
    local itemType, keyType = type(item), type(key)
    if itemType == 'nil' then
        return self
    end

    local vs, ks = self.items, self._keys

    if self.asDict and keyType ~= 'string' then
        key = cstr(key)
    end

    if self.isLcase then
        key = slower(key)
    end
    if self.asList then
        if not (before or after) then
            key = #self._keys + 1
        end
    end

    vs[key] = item
    
    if before then
        local beforeType = type(before)
        if beforeType == 'number' then
            tinsert(ks, before, key)
        elseif beforeType == 'string' then
            local beforePos
            for i, k in ipairs(ks) do
                if k == before then
                    beforePos = i; break
                end
            end
            if beforePos then
                tinsert(ks, beforePos, key)
            end
        end
    else
        if after then
            local afterType = type(after)
            if afterType == 'number' then
                tinsert(ks, after+1, key)
            elseif afterType == 'string' then
                local afterPos
                for i, k in ipairs(ks) do
                    if k == after then
                        afterPos = i; break
                    end
                end
                if afterPos then
                    tinsert(ks, afterPos+1, key)
                end
            end
        else
            tinsert(ks, key)
        end
    end

    return self
end

function _M:bind(tbl)

    if not type(tbl) == 'table' then

        return
    end

    if #tbl > 0 then
        self.asList = true
    else
        self.asDict = true
    end

    self:init(tbl)
end

function _M:keyByIdx(idx)
    local vs, ks = self.items, self._keys
    local kbi = ks[idx]
    
    return kbi
end
 
function _M:itemByIdx(idx, default)

    local vs, ks = self.items, self._keys
    local item

    if idx < 0 then
        idx = self:count() + idx + 1
    end
    if self.asDict then
        local key = self:keyByIdx(idx)
        item = vs[key]
    else
        item = vs[idx]
    end
 
    local dv = default or self.default
    item = utils.fuseValue(item, dv)
    
    return item
end

function _M:itemByKey(key, default)

    local vs, ks = self.items, self._keys
    if self.isLcase then
        key = slower(key)
    end
    local item = vs[key]
    if not item then 
        if self.chainGetable then 
            item = self:getChainItem(key)
        end
    end
    local dv = default or self.default
    item = utils.fuseValue(item, dv)
    
    return item
end

function _M:isChainKey(key)

    local _, keysLen = self:getChainKeys(key)

    return (keysLen > 1) and true or false
end

function _M:getChainKeys(key)

    local nodeKeys = cachedChainKeys[key]
    if not nodeKeys then
        local separator = self.chainSeparator
        nodeKeys = lf.split(key, separator)
        cachedChainKeys[key] = nodeKeys
    end

    local keysLen = #nodeKeys

    return nodeKeys, keysLen
end

function _M:getChainItem(key)

    local lastItem
    local nodeKeys, keysLen = self:getChainKeys(key)

    if keysLen > 1 then
        local eachItem
        local parent = self.items
        for i, k in ipairs(nodeKeys) do
            eachItem = parent[k]
            if eachItem then
                parent = eachItem
                if i == keysLen then
                    lastItem = eachItem
                end
                if type(parent) ~= 'table' then
                    break
                end
            else
                break
            end
        end

        return lastItem
    end
end

function _M:setChainItem(key, value)

    local lastKey
    local nodeKeys, keysLen = self:getChainKeys(key)

    if keysLen > 1 then
        local eachItem, k
        local parent = self.items
        lastKey = nodeKeys[#nodeKeys]

        for i = 1, keysLen - 1 do
            k = nodeKeys[i]
            eachItem = parent[k]
            if eachItem then
                parent = eachItem
 
            else
                parent[k] = {}
                parent = parent[k]
                if i == keysLen -1 then
                    eachItem = parent
                end
            end
        end

        eachItem[lastKey] = value
    end

end

function _M:itemByCb(cb, default)

    if type(cb) ~= 'function' then return end
    
    local vs, ks = self.items, self._keys
    local item,key
    local len
    local t
    if self.asDict then
        len = #ks
        for idx = 1, len do
            key = ks[idx]
            item = vs[key]
            if cb(key, item, idx) then
                t = item
                break
            end
        end
    else
        for idx = 1, #vs do
            item = vs[idx]
            if cb(item, idx) then
                t = item
                break
            end
        end
    end

    local dv = default or self.default
    item = utils.fuseValue(t, dv)
    
    return item
    
end

function _M:get(keyOrIdxOrCb, default)

    local t = keyOrIdxOrCb
    local argType = type(t)

    if argType == 'string' then
        return self:itemByKey(t, default)
    elseif argType == 'number' then
        return self:itemByIdx(t, default)
    elseif argType == 'function' then
        return self:itemByCb(t, default)
    elseif argType == 'table' then
        local titem 
        for _, key in ipairs(t) do
            titem = self:itemByKey(key)
            if titem then
                break
            end
        end
        local dv = default or self.default
        local item = utils.fuseValue(titem, dv)
        return item
    elseif argType == 'nil' then
        error('key or index or callback is nil')
    else
        error('unsupport get type')
    end
end

function _M:set(keyOrIdx, value)

    local vs, ks = self.items, self._keys
    local argType = type(keyOrIdx)
    local key

    if self.asList then
        if argType ~= 'number' then
            return self
        end
        vs[keyOrIdx] = value
    end

    if argType == 'number' then
        key = self:keyByIdx(keyOrIdx)
    elseif argType == 'string' then
        key = keyOrIdx

        if self.chainSetable then
            local separator = self.chainSeparator

            if sfind(key, separator, nil, true) then
                self:setChainItem(key, value)
                return self
            end
        end
    elseif argType == 'table' then
        if next(keyOrIdx) then
            for k, v in pairs(keyOrIdx) do
                self:set(k, v)
            end
            return self
        end
    else

    end

    if self.isLcase then
        key = slower(key)
    end
    
    if key then
        if type(vs[key]) == 'nil' then --key not exists
            self:add(value, key)
        else
            local vType = type(value)
            if vType == 'nil' then --means removeKey
                self:removeByKey(key)
            else
                self:add(value, key)
            end
        end
    end

    return self
end

function _M:removeByKey(key)

    local vs, ks = self.items, self._keys
    if self.isLcase then
        key = slower(key)
    end
    vs[key] = nil
 
    for i,k in ipairs(ks) do
        if k == key then
            tremove(ks, i)
            break
        end
    end
end

function _M:removeByIdx(idx)

    local vs, ks = self.items, self._keys
    if self.asDict then
        local key = ks[idx]
        if key then
            vs[key] = nil
            tremove(ks,idx)
        end
    else
        tremove(ks, #ks)
        Arr.delete(vs, idx, 1)
    end
end

function _M:removeKeys(...)

    local args = {...}
    for k,v in ipairs(args) do
        self:remove(v)
    end
end

function _M:removeByCb(cb)

    if type(cb) ~= 'function' then return end
    
    local vs, ks = self.items, self._keys
    local item,key

    if self.asDict then
        local len = #ks
        for idx = len, 1, -1 do
            key = ks[idx]
            item = vs[key]
            if cb(key, item, idx) then
                self:removeByKey(key)
            end
        end
    else
        for idx = #vs, 1, -1 do
            item = vs[idx]
            if cb(item, idx) then
                tremove(vs, idx)
            end
        end
    end
end

function _M:remove(keyOrIdxOrCb)

    local t = keyOrIdxOrCb
    local argType = type(t)
    if argType == 'number' then
        return self:removeByIdx(t)
    elseif argType == 'string' then
        return self:removeByKey(t)
    elseif argType == 'function' then
        return self:removeByCb(t)
    else
    
    end
end

function _M:count()

    if self.asDict then
        return #self._keys
    else
        return #self.items
    end

    return 0
end

function _M:has(key)

    local vs, ks = self.items, self._keys
    if self.isLcase then
        key = slower(key)
    end
    local ret = vs[key]

    return lf.isset(ret)
end

function _M:hasAny(...)

    local vs, ks = self.items, self._keys
    local isLcase = self.isLcase
    local range, len = lf.needArgs(...)

    if len > 0 then
        local key, has
        for i = 1, len do
            key = range[i]
            if isLcase then
                key = slower(key)
            end
            if vs[key] then
                has = range[i]
                break
            end
        end

        if lf.isset(has) then 
            return has
        end
    end
end

function _M:hasAll(...)

    local vs, ks = self.items, self._keys
    local isLcase = self.isLcase
    local range, len = lf.needArgs(...)

    if len > 0 then
        local hasAll = true
        local key
        for i = 1, len do
            key = range[i]
            if isLcase then
                key = slower(key)
            end
            if not vs[key] then
                hasAll = false
                break
            end
        end

        return hasAll
    end
end

function _M:getAny(...)
     
    local key = self:hasAny(...)

    if key then
        
        return self:get(key)
    end
end

function _M:contains(key, ...)

    local args, len = lf.getArgs(...)
    local operator, value = args[1], args[2]

    if len == 0 then
        if lf.isFunc(key) then
            return self:first(key)
        end
        return Arr.inList(self.items, key)
    end
    if len == 1 then
        value = operator
        operator = '='
    end
    
    return self:contains(self:_operatorForWhere(key, operator, value))
end

function _M:containsStrict(key, ...)

    local args, len = lf.getArgs(...)
    local value = args[1]
    if len == 1 then
        
        return self:contains(function(item)
            
            return Arr.dataGet(item, key) == value
        end)
    end
    if lf.isFunc(key) then
        
        return self:first(key)
    end
    
    return Arr.inList(self.items, key, true)
end

function _M:isEmpty()

    if self:count() == 0 then 
        return true
    else
        return false
    end
end

function _M:isNotEmpty()

    return not self:isEmpty()
end

function _M:initFrom(tbl, asList)
     
    if not asList then
        local tblLen = #tbl
        if tblLen > 0 then
            local k, v
            if math.mod(tblLen, 2) == 0 then
                for i = 1, tblLen, 2 do 
                    k = tbl[i]; v = tbl[i+1]
                    if type(k) ~= 'string' then k = tostring(k) end
                    self:add(v, k)
                end
            end
        else
            for k, v in pairs(tbl) do
                self:add(v, k)
            end
        end
    else
        self.asList = true; self.asDict = false
        Arr.filterNil(tbl)
        self.items = tbl
        self._keys = Arr.keys(tbl)
    end
end

function _M:clear()

    self._keys = {}
    self.items = {}
end
 
function _M:pairs(...)

    local args = {...}
    local argLen = #args
    local items = {}
    local idx = 1
    local t, k 
    local p1 = args[1]
    if type(p1) == 'table' then
        local p2 = args[2]
        if type(p2) ~= 'table' then return end
        if #p1 ~= #p2 then return end
           
        for i, v in ipairs(p1) do
            k = v; v = p2[i]
            t = self:get(k, v)
            if type(t) ~= 'nil' then items[i] = t end
        end
    else
        for i, v in ipairs(args) do
            if math.mod(i,2) == 0 then
                k = args[i-1]
                t = self:get(k, v)
                if type(t) ~= 'nil' then items[idx] = t end
                idx = idx + 1
            end
        end
    end
    
    return unpack(items)
end

function _M:ksort()

    if self.asDict then
        Arr.asort(self.items, self._keys, callback)
        return self:final(self.items, false, self._keys)
    else
        Arr.sort(self.items, callback)
        return self:final(self.items)
    end
end

function _M:sort(callback)
    
    if self.asDict then
        Arr.asort(self.items, self._keys, callback)
        return self:final(self.items, false, self._keys)
    else
        Arr.sort(self.items)
        return self:final(self.items, true)
    end
end

function _M:rsort(callback)
    
    if self.asDict then
        Arr.arsort(self.items, self._keys, callback)
        return self:final(self.items, false, self._keys)
    else
        Arr.rsort(self.items, callback)
        return self:final(self.items)
    end
end

function _M:sortBy(callback, descending)

    local results = Arr.sortBy(self.items, callback, descending)
 
    return self:final(results)
end

function _M:sortByDesc(callback)

    return self:sortBy(callback, true)
end

function _M:unique(key)
    
    local vs, ks = self.items, self._keys
    local id

    if key then
        key = self:_valueRetriever(key)
        local exists = {}
        
        return self:reject(function(item, index)
            id = key(item, index)
            if Arr.inList(exists, id) then
                
                return true
            end
            tapd(exists, id)
        end)
    end

    return self:final(Arr.unique(self.items))
end

function _M:merge(items)

    return self:final(
        Arr.merge(self.items, self:_getArrayableItems(items))
    )
end

function _M:pop()

    local len = self:count()
    local item = self:get(len)
    self:remove(len)

    return item
end

function _M:pick(key, style)

    return Arr.pick(self.items, key, style)
end

function _M:shift()

    local item = self:get(1)
    self:remove(1)

    return item
end

function _M:slice(offset, length)

    return self:final(Arr.slice(self.items, offset, length, true))
end

function _M:walk(cb, ...)
    
    for k, v in self:kv() do
        cb(v, k, ...)
    end
end

function _M:each(cb, ...)
    
    local t
    for k, v in self:kv() do
        t = cb(v, k, ...)
        if lf.isFalse(t) then
            break
        end
    end

    return self
end

function _M:first(callback, default)

    if not callback then
        return self:get(1, default)
    else
        return Arr.first(self.items, callback, default)
    end
end

function _M:last(callback, default)

    if not callback then
        return self:get(self:count(), default)
    else
        return Arr.last(self.items, callback, default)
    end
end

function _M:nth(step, offset)

    offset = offset or 0
    local ret = {}
    local position = 0
    for _, item in self:kv() do
        if position % step == offset then
            tapd(ret, item)
        end
        position = position + 1
    end
    
    return self:final(ret)
end

function _M:all()

    return self.items
end

function _M:sum(target)

    local vs = self.items
    local sum = 0
    if not target then
        for _, v in pairs(vs) do
            sum = sum + v
        end

        return sum
    end

    local targetType = type(target)
    local t
    if targetType == 'string' then
        for _, item in pairs(vs) do
            if type(item) == 'table' then
                t = item[target]
                sum = sum + t
            end
        end
    elseif targetType == 'function' then
        for k, item in pairs(vs) do
            t = target(item, k)
            sum = sum + t
        end
    end

    return sum
end

function _M:avg(target)

    local sum = self:sum(target)
    local count = self:count()
    local ret
    if count > 0 then
        ret = sum / count
    end

    return ret
end

function _M:max(callback)

    callback = self:_valueRetriever(callback)
    
    return self:ad():filter(function(value)
        
        return value
    end):reduce(function(result, item)
        value = callback(item)
        if not result then
            return value
        end
        return Arr.compare(value, result, true) and value or result
    end)
end

function _M:min(callback)

    callback = self:_valueRetriever(callback)
    local value
    return self:reduce(function(result, item)
        value = callback(item)
        if not result then
            return value
        end
        return Arr.compare(value, result) and value or result
    end)
end

function _M:combine(values)

    return self:final(Arr.combine(self:all(), self:_getArrayableItems(values)))
end

function _M:collapse()

    return self:final(Arr.collapse(self.items), 0)
end

function _M:every(key, operator, value)

    local callback
    if not operator then
        callback = self:_valueRetriever(key)
        for k, v in pairs(self.items) do
            if not callback(v, k) then
                
                return false
            end
        end
        
        return true
    end
    if operator and not value then
        value = operator
        operator = '='
    end
    
    return self:every(self:_operatorForWhere(key, operator, value))
end

function _M:chunk(size)

    local chunks = Arr.chunk(self.items, size)
    
    return self:make(chunks)
end

function _M:except(...)

    local keys = lf.needArgs(...)
    local items = Arr.clone(self.items, true) or {}
    for _, key in ipairs(keys) do
        items[key] = nil
    end

    return self:final(items, 0)
end

function _M:filter(cb)

    return self:final(Arr.filter(self.items, cb))
end

function _M:map(cb)

    local items = Arr.map(self.items, cb)

    return self:final(items)
end

function _M:mapSpread(callback)

    return self:map(function(chunk)
        
        return callback(unpack(chunk))
    end)
end

function _M:mapWithKeys(callback)

    return self:flatMap(callback)
end

function _M:flatMap(callback)

    return self:map(callback):collapse()
end

function _M:flip()

    return self:final(Arr.flip(self.items))
end

function _M:forPage(page, perPage)

    return self:slice((page - 1) * perPage + 1, perPage)
end

function _M:forget(...)

    local keys = lf.needArgs(...)
    for _, key in ipairs(keys) do
        self:removeByKey(key)
    end

    return self
end

function _M:where(key, operator, value)

    if lf.isNil(value) then
        value = operator
        operator = '='
    end
    
    return self:filter(self:_operatorForWhere(key, operator, value))
end

function _M:_operatorForWhere(key, operator, value)

    return function(item)
        local value = value
        local retrieved = Arr.dataGet(item, key)
        local st = operator
        local t1, t2 = type(retrieved), type(value)

        if t1 ~= t2 then
            retrieved = cstr(retrieved)
            value = cstr(value)
        end

        if st == '=' or st == '==' then
            return retrieved == value
        elseif st == '!=' or st == '<>' then
            return retrieved ~= value
        elseif st == '<' then
            return retrieved < value
        elseif st == '>' then
            return retrieved > value
        elseif st == '<=' then
            return retrieved <= value
        elseif st == '>=' then
            return retrieved >= value
        elseif st == '===' then
            return t1 == t2 and retrieved == value
        elseif st == '!==' then
            return t1 == t2 or retrieved ~= value
        else
            error('invalid operator:' .. tostring(operator))
        end
    end
end

function _M:whereStrict(key, value)

    return self:where(key, '===', value)
end

function _M:whereIn(key, values, strict)

    strict = strict or false
    values = self:_getArrayableItems(values)
    
    return self:filter(function(item)
        
        return Arr.inList(values, Arr.dataGet(item, key), strict)
    end)
end

function _M:whereInStrict(key, values)

    return self:whereIn(key, values, true)
end

function _M:whereNotIn(key, values, strict)

    strict = strict or false
    values = self:_getArrayableItems(values)
    
    return self:reject(function(item)
        
        return Arr.inList(values, Arr.dataGet(item, key), strict)
    end)
end

function _M:page()

end

function _M:split(numberOfGroups)

    if self:isEmpty() then
        
        return self:final({})
    end
    local groupSize = math.ceil(self:count() / numberOfGroups)
    
    return self:chunk(groupSize)
end

function _M:_valueRetriever(value)

    if lf.isFunc(value) then
        
        return value
    end
    
    return function(item)
        
        return Arr.dataGet(item, value)
    end
end

function _M:groupBy(groupBy, preserveKeys)

    preserveKeys = preserveKeys or false
    local groupKeys
    groupBy = self:_valueRetriever(groupBy)
    local results = {}

    for key, value in self:kv() do
        groupKeys = groupBy(value, key)
        if not lf.isTbl(groupKeys) then
            groupKeys = {groupKeys}
        end

        for _, groupKey in ipairs(groupKeys) do
            if not Arr.has(results, groupKey) then
                results[groupKey] = {}
            end
            if preserveKeys then
                results[groupKey][key] = value
            else
                tapd(results[groupKey], value)
            end
        end
    end
    
    return self:final(results, #results > 0)
end

function _M:keyBy(keyBy)

    keyBy = self:_valueRetriever(keyBy)
    local results = {}
    for key, item in self:kv() do
        results[cstr(keyBy(item, key))] = item
    end

    return self:final(results, false)
end

function _M:pipe(callback)

    return callback(self)
end

function _M:implode(value, glue)

    local first = self:first()
    if lf.isTbl(first) or lf.isObj(first) then

        return Str.join(self:ad():pluck(value):all(), glue)
    end
    
    return Str.join(self.items, value)
end

function _M:intersect(items)

    return self:final(
        Arr.same(self.items, self:_getArrayableItems(items))
    )
end

function _M:diff(items)

    return self:final(
        Arr.diff(self.items, self:_getArrayableItems(items))
    )
end

function _M:diffKeys(items)

    return self:final(
        Arr.diffKey(self.items, self:_getArrayableItems(items))
    )
end

function _M:mode(key)

    local count = self:count()
    if count == 0 then
        
        return
    end
    local collection = key and self:pluck(key) or self
    local counts = self:final({}, false):itemable()
    local t
    collection:each(function(value)
        value = cstr(value)
        t = counts:get(value)
        counts:set(value, t and t + 1 or 1)
    end)

    local sorted = counts:sort()

    local highestValue = sorted:last()

    return sorted:filter(function(value)
        
        return value == highestValue
    end):sort():keys():all()
end

function _M:only(...)

    local keys = lf.needArgs(...)
    local vs = self.items

    return self:final(Arr.only(vs, keys))
end

function _M:pluck(value, key)

    local values = self.items

    return self:final(Arr.pluck(values, value, key), 0)
end

function _M:splice(offset, length, replacement)

    replacement = replacement or {}
    if not (length or replacement) then
        
        return self:make(Arr.splice(self.items, offset))
    end
    
    return self:make(Arr.splice(self.items, offset, length, replacement))
end

function _M:prepend(value, key)

    self.items = Arr.prepend(self.items, value, key)
    
    return self
end

function _M:pull(key, default)

    return Arr.pull(self.items, key, default)
end

function _M:push(value)

    tapd(self.items, value)

    return self
end

function _M:random(amount)

    amount = amount or 1
    local vs, ks = self.items, self._keys

    if self.asList then
        ks = Arr.range(1, #vs)
    end
    local rndKeys = Arr.rand(ks, amount)
    local ret
    
    if amount == 1 then
        ret = vs[rndKeys]
    else
        ret = {}
        for _, key in ipairs(rndKeys) do
            tapd(ret, vs[key])
        end
    end

    return ret
end

function _M:reduce(cb, initial)
    
    local ret = initial
    local vs = self.items

    for k, v in pairs(vs) do
        ret = cb(ret, v)
    end

    return ret
end

function _M:reject(callback)

    local ret = Arr.reject(self.items, callback)

    return self:final(ret)
end

function _M:reverse()

    if self.asList then
        return self:final(Arr.reverse(self.items, true))
    else
        return self:final(self.items, false, Arr.reverse(self._keys))
    end
end

function _M:search(value, strict)

    strict = strict or false
    if not lf.isFunc(value) then
        
        return Arr.search(self.items, value, strict)
    end
    for key, item in self:kv() do
        if lf.call(value, item, key) then
            
            return key
        end
    end
    
    return false
end

function _M:union(items)

    return self:final(
        Arr.mergeTo(self:_getArrayableItems(items), self.items)
    )
end

function _M:take(limit)

    if limit < 0 then
        
        return self:slice(limit, math.abs(limit))
    end
    
    return self:slice(1, limit)
end

function _M:flatten(depth)

    if not depth then
        depth = 99
    end
 
    local vs = self.items

    return self:final(Arr.flatten(vs, depth))
end

function _M:dot(prepend)
 
    return Arr.dot(self.items, prepend)
end

function _M:join(value, glue)

    return Str.join(self.items, value)
end

function _M:tap(callback)

    callback(self:final(self.items))

    return self
end

function _M:times(amount, callback)

    if amount < 1 then
        return self:new():init()
    end

    if not callback then
        return self:new():useList():init(Arr.range(1, amount))
    end

    local col = self:new():useList():init(Arr.range(1, amount))
        :ad():map(callback)

    return col
end

function _M:zip(...)

    local args = {...}
    local arrayableItems = Arr.map(args, function(items)
        
        return self:_getArrayableItems(items)
    end)

    local params = {}
    local item
    for i, v in ipairs(self.items) do
        item = {}
        tapd(item, v)
        for _, vv in ipairs(arrayableItems) do
            tapd(item, vv[i])
        end
        tapd(params, item)
    end

    return self:final(params)
end

function _M:partition(callback)

    local partitions = {{}, {}}
    callback = self:_valueRetriever(callback)
    for key, item in pairs(self.items) do
        local pos = callback(item) and 1 or 2
        if self.asDict then
            partitions[pos][key] = item
        else
            tapd(partitions[pos], item)
        end
    end

    return self:final(partitions, true)
end

function _M:mapToGroups(callback)

    local groups = self:ad():map(callback):reduce(function(groups, pair)
        local key, value = next(pair)
        Arr.mapd(groups, key, value)
        
        return groups
    end, {})
    
    return self:make(groups)
end

function _M:when(value, callback, default)

    if value then
        return callback(self)
    elseif default then
        return default(self)
    end

    return self
end

function _M:transform(callback)

    local items = Arr.map(self.items, callback)
    self.items = items

    return self
end

function _M:_getArrayableItems(items)

    if lf.isObj(items) then
        if items:__is('col') then
            return items:all()
        elseif items:__is('arrayable') then
            return items:toArr()
        elseif items:__is('jsonable') then
            return lx.json.decode(items:toJson())
        elseif items:__is('eachable') then
            return lf.eachToArr(items)
        end
    elseif lf.isTbl(items) then
        return items
    end

    return lf.needList(items)
end

local function mtMethod(p1, p2, mtType)

    local p1Type, p2Type = type(p1), type(p2)
    if not (p1Type == 'table' and p2Type == 'table') then
        return
    end

    local ret
    local p1Cls, p2Cls = p1.__cls, p2.__cls
    if p1Cls and p2Cls then
        p1, p2 = p1.items, p1.items
    elseif p1Cls then
        p1 = p1.items
    else
        p2 = p1.items
    end

    if mtType == 'add' then
        return Arr.merge(p2, p1)
    elseif mtType == 'sub' then
        return Arr.diffKey(p1, p2)
    elseif mtType == 'mul' then

    elseif mtType == 'div' then

    end

end

local function mtAdd(p1, p2)

    return mtMethod(p1, p2, 'add')
end

local function mtSub(p1, p2)
    return mtMethod(p1, p2, 'sub') 
end

local function mtMul(p1, p2)
    return mtMethod(p1, p2, 'mul') 
end

local function mtDiv(p1, p2)
    return mtMethod(p1, p2, 'div') 
end

mt.__add = mtAdd
mt.__sub = mtSub
mt.__mul = mtMul
mt.__div = mtDiv
mt.__call = function(self, ...)
    
    return self:get(...)
end

return _M

