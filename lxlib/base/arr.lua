
local _M = {
    _cls_ = ''
}

local mt = { __index = _M }

local colBase = require('lxlib.base.col')
local json = require('lxlib.json.base')
local lf = require('lxlib.base.pub')
local Str = require('lxlib.base.str')
local utils = require('lxlib.base.utils')

local cachedChainKeys = {}
local type = type
local tremove, tinsert, tconcat, tsort = table.remove, table.insert, table.concat, table.sort
local tmaxn = table.maxn
local cstr, cint = tostring, tonumber
local sfind, ssub = string.find, string.sub
local each = lf.each

function _M.count(tbl, deep)
    
    local ret = 0
    local deep = deep or 0
    if type(tbl) == 'table' then
        ret = #tbl

        if ret > 0 and deep == 1 then
            ret = 0
            for _, v in ipairs(tbl) do
                if type(v) == 'table' then
                    ret = ret + _M.count(v, deep)
                else
                    ret = ret + 1
                end
            end
        end
        if ret == 0 and next(tbl) then
            ret = 0
            if lf.isObj(tbl) and tbl:__is('countable') then
                ret = tbl:count()
            else
                for _, v in pairs(tbl) do
                    if deep == 1 and type(v) == 'table' then
                        ret = ret + _M.count(v, deep)
                    else
                        ret = ret + 1
                    end
                end
            end
        end
    end
 
    return ret
end

function _M.append(tbl, item)

    tbl[#tbl+1] = item
end

_M.apd = _M.append

function _M.toCol(scData)
    local typ = type(scData)

    local col = colBase:new()
    
    if typ == 'table' then
        col:initFrom(scData)
        
    elseif typ == 'string' then
        local tbl = json.decode(scData)
        col:initFrom(tbl)
    end
    
    return col
end

function _M.getDictLen(dict)

    local ret = 0 
    if dict then
        for k, v in pairs(dict) do
            ret = ret + 1
        end
    else
        ret = 0 
    end

    return ret
end

function _M.listMergeDict(jsonArr, jsonObj)
    
    if #jsonObj > 0 then
        local t = jsonObj[1]
        if type(t) == 'table' then
            jsonObj = t
        else
            return
        end
    end
    
    if #jsonArr == 0 then return end
    if not next(jsonObj) then return end
 
    local itemType 
    for _, arrItem in ipairs(jsonArr) do
        itemType = type(arrItem)
        if itemType == 'table' then
            for k, v in pairs(jsonObj) do
                if not arrItem[k] then
                    arrItem[k] = v
                end
            end
        end
    end
end

function _M.mergeListByKey(tbl, keyInfo, convertStyle)

    -- 1:whenNeedToList; 2:alwaysToList;
    local style = convertStyle or 2
    if style > 2 then return {} end
    
    local rowKey,nodeKey
    local keyInfoType = type(keyInfo)
    if keyInfoType == 'string' then
        rowKey = keyInfo
    elseif keyInfoType == 'table' then
        rowKey, nodeKey = unpack(keyInfo)
    end

    local eOldRow, eRowKey, eNodeKey
    local newRoot = {}
    local tSubCol,tSub2Col = {}, {}
    local t = {}
    for _, eOldRow in ipairs(tbl) do
        eRowKey = eOldRow[rowKey]
        if eRowKey then
            eRowKey = cstr(eRowKey)
            tSubCol = newRoot[eRowKey]
            if not tSubCol then
                if nodeKey then
                    eNodeKey = eOldRow[nodeKey]
                    if eNodeKey then
                        eNodeKey = cstr(eNodeKey)
                        tSubCol = {}
                        if style == 1 then 
                            tSubCol[eNodeKey] = eOldRow
                        elseif style == 2 then
                            tSubCol[eNodeKey] = {eOldRow}
                        end
                    else
                        reutrn {}
                    end
                else
                    tSubCol = {eOldRow}
                end
                newRoot[eRowKey] = tSubCol
            else
                if nodeKey then
                    eNodeKey = eOldRow[nodeKey]
                    if eNodeKey then
                        eNodeKey = cstr(eNodeKey)
                        tSub2Col = tSubCol[eNodeKey]
                        if tSub2Col then
                            if #tSub2Col == 0 then
                                t = {}
                                for k,v in pairs(tSub2Col) do t[k] = v end
                                tSub2Col = {t}
                            end
                            tapd(tSub2Col, eOldRow)
                            tSubCol[eNodeKey] = tSub2Col
                        else
                            if style == 1 then
                                tSubCol[eNodeKey] = eOldRow
                            elseif style == 2 then
                                tSubCol[eNodeKey] = {eOldRow}    
                            end
                        end
                    else
                        return {}
                    end
                else
                    tapd(tSubCol,eOldRow)
                end
            end
        else
            return {}
        end
    end
    
    return newRoot
end

_M.pick = _M.mergeListByKey

function _M.checkTableFirstNodeDeep(tbl, parentLevel)

    local level = parentLevel or 0
    local t
    
    if type(tbl) == 'table' then
        if tbl then
            if #tbl > 0 then
                t = tbl[1]
                if type(t) == 'table' then
                    level = _M.checkTableFirstNodeDeep(t,level)
                    level = level + 1
                else
                    level = level + 1
                end
            end
        end
    else
        level = 0 
    end
    
    return level
end

local function checkItemValue(item, dv)
 
    local itemType = type(item)
    if itemType == 'nil' then
        item = dv
    else
        if dv then
            local dvType = type(dv)
            if dvType ~= itemType then
                if dvType == 'number' then
                    item = cint(item)
                    if not item then
                        item = dv
                    end
                elseif dvType == 'string' then
                    item = cstr(item)
                elseif dvType == 'boolean' then
                    item = true
                elseif dvType == 'table' then
                    item = {}
                end
            end
        end
    end
    
    return item
end

function _M.copyDictItemByKeys(fromDict, toDict, keys, keysTbl)

    _M.copyDictByKeys(fromDict, toDict, keys, keysTbl)
end

function _M.copyDictByKeys(fromDict, toDict, keys, keysTbl)

    local dft, item, key
    if keys then
        for _, k in ipairs(keys) do
            if type(k) == 'table' then
                key, dft = k[1], k[2]
                item = fromDict[key]
                item = checkItemValue(item, dft)
                toDict[key] = item
            else
                toDict[k] = fromDict[k]
            end
        end
    end

    if keysTbl then
        for k, v in pairs(keysTbl) do
            if type(v) == 'table' then
                key, dft = v[1], v[2]
                item = fromDict[key]
                item = checkItemValue(item, dft)
                toDict[k] = item
            else
                toDict[k] = fromDict[v]
            end
        end    
    end

end

function _M.copyList(tbl)

    local ret = {}
    for i = 1, tmaxn(tbl) do
        ret[i] = tbl[i]
    end

    return ret
end

function _M.listAdds(list, data)
    
    for _, v in pairs(data) do
        list[#list+1] = v
    end
end
 
function _M.dictRemoveKeys(dict, ...)

    local keys = {}
    local args = {...}
    local p1 = args[1]
    if type(p1) == 'table' then
        keys = p1
    else
        keys = args
    end

    for _, key in ipairs(keys) do 
        if dict[key] then
            dict[key] = nil
        end
    end

end

function _M.cleanup(tbl)

    local len = #tbl
    if len > 0 then
        for idx = len, 1, -1 do
            if type(tbl[idx]) == 'table' then 
                tremove(tbl, idx)
            end
        end
    else
        for k, v in pairs(tbl) do
            if type(v) == 'table' then
                tbl[k] = nil
            end
        end
    end
end

function _M.clear(tbl)

    local len = #tbl
    if len > 0 then
        for i = len, 1, -1 do
            tremove(tbl, i)
        end
    end

    if next(tbl) then
        for k, v in pairs(tbl) do
            tbl[k] = nil
        end
    end
end

function _M.removeFunc(tbl)

    for k, v in pairs(tbl) do
        if type(v) == 'function' then
            tbl[k] = nil
        elseif type(v) == 'table' then
            _M.removeFunc(v)
        end
    end
end

function _M.dictAdds(dict, ...)

    local items = {}
    local args = {...}
    local p1 = args[1]
    if type(p1) == 'table' then
        items = p1
    else
        for i, t in ipairs(args) do
            if math.mod(i, 2) == 0 then
                items[args[i-1]] = t
            end
        end
    end

    for k,v in pairs(items) do
        dict[k] = v
    end
end

function _M.splice(tbl, offset, length, replacement)

    local ret = {}
    if not tbl then return ret end
    local len = #tbl
    if len == 0 then return ret end

    local first, last = utils.getRange(len, offset, length)

    if first <= len then
        if length and length == 0 then

        else
            for i = last, first, -1 do
                tinsert(ret, 1, tbl[i])
                _M.remove(tbl, i, 1)
            end
        end
        if replacement then
            replacement = lf.needList(replacement)
            for k, v in ipairs(replacement) do
                tinsert(tbl, first + k - 1, replacement[k])
            end
        end
    end

    return ret
end

function _M.unique(vs, byref, callback)

    if type(vs) ~= 'table' then
        return {}
    end

    local ret = {}

    local needRemoves
    if byref then
        needRemoves = {} 
    end

    if #vs > 0 then
        local len, hashs = #vs, {}
        local t, v
        for i = 1, len do
            v = vs[i]
            if callback then
                t = cstr(callback(v))
            else
                t = cstr(v)
            end
            if hashs[t] then
                if byref then
                    tapd(needRemoves, i)
                end
            else
                hashs[t] = 1
                tapd(ret, v)
            end
        end

        if byref then
            for i = #needRemoves, 1, -1 do
                tremove(vs, needRemoves[i])
            end
        end
    else
        if not next(vs) then return {} end

        local hashs = {}
        local t

        for k, v in pairs(vs) do
            if callback then
                t = cstr(callback(v))
            else
                t = cstr(v)
            end
            if hashs[t] then
                if byref then
                    vs[k] = nil
                end
            else
                hashs[t] = 1
                ret[k] = v
            end
        end
    end

    return ret
end

local function mergeTbls(...)

    local args = {...}
    local tempTbl = {}
    for _, tbl in ipairs(args) do
        for _, v in pairs(tbl) do
            if not tempTbl[v] then
                tempTbl[v] = v
            end
        end
    end

    return tempTbl
end

local function filterChainItemIndex(key)

    if ssub(key,1,1) == "[" and ssub(key,-1) == "]" then
        key = ssub(key,2,-2)
        key = cint(key) or error('invalid index')
    end

    return key
end

function _M.getChainItem(tbl, key, default)

    local lastItem
    local nodeKeys, keysLen = _M.getChainKeys(key)
 
    if keysLen > 1 then
        local eachItem
        local parent = tbl
        for i, k in ipairs(nodeKeys) do
            k = filterChainItemIndex(k)
            eachItem = parent[k]
            if not lf.isNil(eachItem) then
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
    end

    return lf.isNil(lastItem) and default or lastItem
end

function _M.setChainItem(tbl, key, value)

    local lastKey
    local nodeKeys, keysLen = _M.getChainKeys(key)

    if keysLen > 1 then
        local eachItem, k
        local parent = tbl
        lastKey = nodeKeys[#nodeKeys]
        lastKey = filterChainItemIndex(lastKey)
        for i = 1, keysLen - 1 do
            k = nodeKeys[i]
            k = filterChainItemIndex(k)
            eachItem = parent[k]
            if eachItem then
                parent = eachItem
 
            else
                parent[k] = {}
                parent = parent[k]
                if i == keysLen - 1 then
                    eachItem = parent
                end
            end
        end

        if type(eachItem) == 'table' then
            eachItem[lastKey] = value
        end
    end
end

function _M.isChainKey(key)

    local nodeKeys, keysLen = _M.getChainKeys(key)

    return (keysLen > 1) and true or false
end

function _M.getChainKeys(key)
 
    local nodeKeys = cachedChainKeys[key]
    if not nodeKeys then
        nodeKeys = lf.split(key, '.')
        cachedChainKeys[key] = nodeKeys
    end
    local keysLen = #nodeKeys

    return nodeKeys, keysLen
end

function _M.unsetChainItem(tbl, key)

    local lastKey
    local nodeKeys, keysLen = _M.getChainKeys(key)

    if keysLen > 1 then
        local eachItem, k
        local parent = tbl
        lastKey = nodeKeys[#nodeKeys]
 
        for i = 1, keysLen - 1 do
            k = nodeKeys[i]
 
            eachItem = parent[k]
            if eachItem then
                parent = eachItem
 
            else
                return 
            end
        end
        if keysLen == 1 then 
            eachItem = tbl
        end

        if eachItem then
            if type(eachItem) == 'table' then
                eachItem[lastKey] = nil
            end
        end
    end
end

function _M.forget(tbl, ...)

    local keys = lf.needArgs(...)

    for _, key in ipairs(keys) do
        if (not tbl[key]) and _M.isChainKey(key) then
            _M.unsetChainItem(tbl, key)
        else
            if #tbl > 0 then
                _M.remove(tbl, key, 1)
            else
                tbl[key] = nil
            end
        end
    end

    return tbl
end

function _M.intersect(tbl1, ...)

    local ret = {}
    if not tbl1 then return {} end
    if not next(tbl1) then return ret end

    local otherTbls = {...}
    local valuesList = {}
    local values
    for _, et in ipairs(otherTbls) do
        values = {}
        for k, v in pairs(et) do
            v = tostring(v)
            values[v] = v
        end
        tapd(valuesList, values)
    end

    local allHas
    for k, v in pairs(tbl1) do
        allHas = true
        v = tostring(v)
        for _, et in ipairs(valuesList) do
            if not et[v] then
                allHas = false
                break
            end
        end
        if allHas then
            ret[k] = v
        end
    end

    return ret
end

_M.same = _M.intersect

function _M.intersectKey(tbl1, ...)

    local ret = {}
    if not tbl1 then return {} end
    if not next(tbl1) then return ret end

    local args = {...}

    local allHas = true
    for k, v in pairs(tbl1) do
        allHas = true
        for _, et in ipairs(args) do
            if not et[k] then
                allHas = false
                break
            end
        end
        if allHas then
            ret[k] = v
        end
    end

    return ret
end

_M.cross = _M.intersectKey

function _M.flip(tbl, discardKeys)

    local ret = {}

    if not tbl then return ret end

    local vt = type(tbl)
    if vt == 'string' then
        tbl = Str.split(tbl, ',')
    end
    
    for k, v in pairs(tbl) do
        if discardKeys then
            k = v
        end
        ret[v] = k
    end

    return ret
end

function _M.add(tbl, key, value)

    if not _M.get(tbl, key) then
        _M.set(tbl,key, value)
    end

    return tbl
end

function _M.build(tbl, cb)

    local result = {}
    local innerKey, innerValue
    for k, v in pairs(tbl) do
        innerKey, innerValue = cb(k, v)
        result[innerKey] = innerValue
    end

    return result
end

function _M.divide(tbl)
    
    local keys, values = {}, {}

    for k, v in pairs(tbl) do
        keys[#keys + 1] = k
        values[#values + 1] = v
    end

    return keys, values
end

function _M.except(tbl, ...)

    _M.forget(tbl, ...)

    return tbl
end

function _M.first(tbl, cb, default)

    if cb then
        for k, v in pairs(tbl) do 
            if cb(v, k) then
                return v
            end 
        end
    else
        return tbl[1]
    end

    return default
end

function _M.last(tbl, cb, default)

    local value

    if cb then
        for k, v in pairs(tbl) do
            if cb(v, k) then
                value = v
            end
        end
        if not lf.isNil(value) then
            return value
        end
    else
        if #tbl > 0 then
            return tbl[#tbl]
        end
    end

    return default
end

function _M.max(tbl, needIndex)

    local values
    if #tbl > 0 then
        values = tbl
    else next(tbl)
        values = _M.values(tbl)
    end
    local maxValue = math.max(unpack(values))
    if needIndex then
        for k, v in pairs(tbl) do
            if v == maxValue then
                return maxValue, k
            end
        end
    else
        return maxValue
    end
end

function _M.search(tbl, value, strict)

    if not tbl or not value then
        return false
    end
    
    for k, v in pairs(tbl) do
        if not strict then
            if v == value then
                return k
            end
        else
            if type(v) == type(value) and v == value then
                return k
            end
        end
    end

    return false
end

function _M.explodePluckParameters(value, key)

    if not key then
        return value
    end

    if lf.isStr(value) and lf.isStr(key) then
        if not Str.find(value, '%.') and not Str.find(key, '%.') then
            return value, key
        else
            return value, key
        end
    elseif lf.isTbl(value) or lf.isTbl(key) then
        return value, key
    else
        return value, key
    end
end

function _M.pluck(tbl, value, key)

    local ret = {}

    value, key = _M.explodePluckParameters(value, key)
    local isFuncValue = type(value) == 'function'

    local itemValue, itemKey
    for k, item in pairs(tbl) do

        if isFuncValue then
            itemValue = value(item, k)
        else
            itemValue = _M.dataGet(item, value)
        end
        if not key then
            tapd(ret, itemValue)
        else
            itemKey = _M.dataGet(item, key)
            ret[itemKey] = itemValue
        end
    end

    return ret
end

function _M.get(tbl, key, default)

    if not lf.isTbl(tbl) then
        return utils.fuseValue(nil, default)
    end

    if not key then 
        return tbl
    end

    local value = tbl[key]
    if (not value) and type(value) == 'nil' then
        value = _M.getChainItem(tbl, key)
    end

    if default then
        value = utils.fuseValue(value, default)
    end

    return value
end

function _M.gain(tbl, ...)

    local ret
    local t = tbl
    local args = {...}
    local len = #args

    for i, key in ipairs(args) do
        t = t[key]

        if type(t) ~= 'table' then
            if i < len then
                return
            end
        end
    end

    return t
end

function _M.set(tbl, key, value, other, ...)
    
    if not key then
        return tbl
    end

    if not other then
        if sfind(key, '%.') then
            _M.setChainItem(tbl, key, value)
        else
            tbl[key] = value
        end
    else
        local paths, finalValue
        local args = {...}
        if #args > 0 then
            finalValue = args[#args]
            paths = {key, value, other}
            for i = 1, #args - 1 do
                tapd(paths, args[i])
            end
        else
            paths = {key, value}
            finalValue = other
        end

        local path, t
        local arr = tbl

        for i = 1, #paths -1 do
            path = paths[i]
            t = arr[path]
            if t then
                arr = t
            else
                arr[path] = {}
                arr = arr[path]
            end
        end
        path = paths[#paths]

        arr[path] = finalValue
    end

end

function _M.exists(tbl, key)

    if lf.isA(tbl, 'col') then
        tbl = tbl:all()
    end

    if not key then
        return false
    end
    local value = tbl[key]
    if lf.notNil(value) then

        return true
    end

    return false
end

function _M.has(tbl, key)

    if not tbl then
        return false
    end
    if not key then
        return false
    end
    local value = tbl[key]
    if not lf.isNil(value) then
        return true
    end

    if lf.isStr(key) then
        if not lf.isNil(_M.getChainItem(tbl, key)) then 
            return true
        end
    elseif lf.isTbl(key) then
        if not next(key) then
            return false
        end
        local keys = key
        for _, key in ipairs(keys) do
            if not _M.has(tbl, key) then 
                return false
            end
        end

        return true
    end

    return false
end

function _M.inList(tbl, value, strict)

    local vt = type(value)
    if vt == 'nil' then return false end

    local len = #tbl
    if len == 0 then return false end

    local t
    for _, v in pairs(tbl) do
        t = type(v)
        if strict then
            if vt == t then
                if v == value then
                    return true 
                end
            end
        else
            if vt ~= t then
                v = cstr(v)
                value = cstr(value)
            end
            if v == value then
                return true 
            end
        end
    end

    return false
end

function _M.contains(tbl, value, other)

    if not value then return false end
 
    local vt = type(value)

    if vt == 'function' then
        for k, v in pairs(tbl) do
            if value(k, v) then
                return true
            end
        end
    else
        if not other then
            for _, v in pairs(tbl) do
                if v == value then
                    return true
                end
            end
        else
            local key = value
            value = other
            if #tbl > 0 then
                for _, item in ipairs(tbl) do
                    if item[key] == value then
                        return true
                    end
                end
            end
        end
    end
     
    return false
end

_M.contain = _M.contains

function _M.isEmpty(tbl)

    if not tbl then return true end

    if #tbl > 0 then
        return false
    elseif next(tbl) then
        return false
    else 
        return true
    end
end

function _M.shift(tbl)

    if not next(tbl) then
        return
    end

    local item = tbl[1]
    tremove(tbl, 1)

    return item
end

function _M.unshift(tbl, ...)

    local args = {...}

    for i, v in ipairs(args) do
        tinsert(tbl, i, v)
    end

    return tbl
end

function _M.pop(tbl)

    local len = #tbl
    local item = tbl[len]
    
    tremove(tbl, len)

    return item
end

function _M.push(tbl, ...)
    
    local args, len = lf.getArgs(...)
    if len == 1 then
        tbl[#tbl+1] = args[1]
    elseif len > 1 then
        for i = 1, len do
            tbl[#tbl+1] = args[i]
        end
    end

    return tbl
end

function _M.reverse(tbl)
    
    local ret = {}
    local len = #tbl
    for i = 1, len do
        ret[i] = tbl[len - i + 1]
    end

    return ret
end

function _M.rand(tbl, num)

    num = num or 1
    local ret
    local len = #tbl
    local tmp

    if len > 0 then
        tmp = tbl
    else
        if next(tbl) then
            tmp = {}
            for k, v in pairs(tbl) do
                tapd(tmp, v)
            end
            len = #tmp
        end
    end

    local rnd, i
 
    if len > 0 then 
        if num == 1 then
            rnd = lf.randnum(1, len)
            ret = tmp[rnd]
        else
            ret = {}
            rnd = lf.rands(1, len, num)

            for i = 1, num do 
                ret[i] = tmp[rnd[i]]
            end
        end
    end

    return ret
end

function _M.shuffle(tbl)
 
    local ret
    local len = #tbl
    local tmp

    if len > 0 then
        tmp = {}
        for _, v in ipairs(tbl) do
            tapd(tmp, v)
        end
    else
        if next(tbl) then
            tmp = {}
            for k, v in pairs(tbl) do
                tapd(tmp, v)
            end
            len = #tmp
        end
    end
 
    if len > 0 then
        local rnd, t
        for i = 1, len do
            rnd = lf.randnum(1, len)
            t = tmp[i]
            tmp[i] = tmp[rnd]
            tmp[rnd] = t
        end
    end

    return tmp
end

function _M.only(tbl, keys)

    local ret = {}
    local t

    if #keys == 0 then
        return tbl
    end
    for _, k in ipairs(keys) do
        t = tbl[k]
        if t then
            ret[k] = t
        end
    end

    return ret
end

function _M.prepend(tbl, value, key)

    if not key then
        tinsert(tbl, 1, value)
    else
        tbl[key] = value
    end

    return tbl
end

function _M.pull(tbl, key, default)

    local item = _M.get(tbl, key, default)
    _M.forget(tbl, key)

    return item
end

function _M.filterNil(tbl)

    local max = tmaxn(tbl)
    local record = {}
    local t
    for i = max, 1, -1 do
        t = tbl[i]
        if type(t) == 'nil' then
            tbl[i] = true
            tapd(record, i)
        end
    end

    if #record > 0 then
        for i, v in ipairs(record) do
            tremove(tbl, v)
        end
    end

    return tbl
end

function _M.delete(tbl, pos)

    local len = tmaxn(tbl)
    local item = tbl[pos]
    if pos < len then
        local after = tbl[pos + 1]
        if type(after) == 'nil' then
            tbl[pos + 1] = true
            tremove(tbl, pos)
            tbl[pos] = nil
        else
            if type(item) == 'nil' then
                tbl[pos] = true
                tremove(tbl, pos)
            else
                tremove(tbl, pos)
            end
        end
    else

        tremove(tbl, pos)
    end

    return item
end

function _M.compare(a, b, desc)
    
    desc = desc or false
    local vta, vtb = type(a), type(b)

    if not a and vta == 'nil' then
        return not desc
    end
    if not b and vtb == 'nil' then
        return desc
    end

    if vta ~= vtb then
        if vta == 'string' then
            if vtb ~= 'string' then
                b = cstr(b)
            end
        else
            if vtb == 'string' then
                a = cstr(a)
            end
        end
    end

    local ret = a < b
    if desc then
        ret = not ret
    end

    return ret
end

function _M.sort(tbl, cb)
    
    if cb then 
        tsort(tbl, cb)
    else
        tsort(tbl, _M.compare)
    end

    return tbl
end

function _M.rsort(tbl, cb)

    if cb then 
        tsort(tbl, cb)
    else
        tsort(tbl)
    end

    local rtbl = _M.reverse(tbl)
    for k, v in ipairs(rtbl) do
        tbl[k] = v
    end

    return tbl
end

function _M.sortBy(tbl, callback, descending)

    descending = descending or false

    local vt = type(callback)
    local isCallable, key
    if vt == 'function' then
        isCallable = true
    else
        isCallable = false
        key = callback
    end

    local cb = function(a, b)
        if isCallable then
            return _M.compare(callback(a), callback(b))
        else
            return _M.compare(a[key], b[key])
        end
    end

    if descending then
        _M.rsort(tbl, cb)
    else
        tsort(tbl, cb)
    end
 
    return tbl
end

function _M.sortRecursive(tbl)

    for _, v in pairs(tbl) do 
        if lf.isTbl(v) then
            _M.sortRecursive(v)
        end
    end

    -- if _M.isAssoc(tbl) then
    --     _M.ksort(tbl)
    -- else
    --     _M.sort(tbl)
    -- end
end

function _M.asort(values, keys)

    tsort(keys, function(a, b)
        
        return _M.compare(values[a], values[b])
    end)

    -- _M.sort(values)

    return values, keys
end


function _M.arsort(values, keys)

    tsort(keys, function(a, b)
        
        return _M.compare(values[a], values[b], true)
    end)

    _M.rsort(values)

    return values, keys
end

function _M.mergeDict(...)

    local ret = {}
    local args = {...}
    for _, tbl in ipairs(args) do
        for k, v in pairs(tbl) do 
            ret[k] = v
        end
    end

    return ret
end

function _M.merge(...)

    local ret = {}
    local args = {...}
    local kType
     
    for _, tbl in ipairs(args) do
        for k, v in pairs(tbl) do 
            kType = type(k)
            if kType == 'string' then
                ret[k] = v
            elseif kType == 'number' then
                ret[#ret + 1] = v
            end
        end
    end

    return ret
end

function _M.mergeTo(to, from)

    for k, v in pairs(from) do
        to[k] = v
    end

    return to
end

function _M.mergeList(...)
    
    local ret = {}
    local args = {...}
    for _, tbl in ipairs(args) do
        for _, v in pairs(tbl) do 
            ret[#ret+1] = v
        end
    end

    return ret
end

function _M.deepMerge(...)

    local ret = {}
    local args = {...}
    local kt, vt, t
     
    for _, tbl in ipairs(args) do
        for k, v in pairs(tbl) do 
            kt, vt = type(k), type(v)
            if vt == 'table' then
                t = ret[k]
                if t then
                    v = _M.deepMerge(t, v)
                end
            end
            if kt == 'string' then
                ret[k] = v
            elseif kt == 'number' then
                ret[#ret + 1] = v
            end
        end
    end

    return ret
end

function _M.dot(tbl, prepend)

    local ret = {}
    prepend = prepend or ''
    for k, v in pairs(tbl) do 
        if type(v) == 'table' and next(v) then
            ret = _M.merge(ret, _M.dot(v, prepend .. k .. '.'))
        else
            ret[prepend .. k] = v
        end
    end

    return ret
end

function _M.rdot(tbl)

    local ret = {}
 
    for k, v in pairs(tbl) do
        _M.set(ret, k, v)
    end

    return ret
end

function _M.mix(...)

    local ret = {}
    local tbls = {...}
    local doted = {}

    for _, v in ipairs(tbls) do
        tapd(doted, _M.dot(v))
    end

    local merged = _M.mergeDict(unpack(doted))

    ret = _M.rdot(merged)

    return ret
end

function _M.walk(tbl, callable)

    for k, v in pairs(tbl) do
        lf.call(callable, v, k)
    end
end

function _M.reduce(tbl, cb, initial)

    local ret = initial

    for k, v in pairs(tbl) do
        ret = cb(ret, v)
    end

    return ret
end

function _M.map(...)

    local ret = {}
    local tbls = {...}
    local callable = _M.pop(tbls)
    local len = #tbls
    local tbl

    if len == 1 then
        tbl = tbls[1]
        for k, v in pairs(tbl) do
            ret[k] = lf.call(callable, v)
        end
    elseif len > 1 then
        tbl = tbls[1]
        for k, v in ipairs(tbl) do
            local params = {}
            for i = 1, len do
                tapd(params, tbls[i][k])
            end
            ret[k] = lf.call(callable, unpack(params))
        end
    end

    return ret
end

function _M.flatten(tbl, depth)

    if not depth then
        depth = 99
    end
 
    local result = {}
    local cb = lf.use{depth = depth, function(ret, item)
        local tmp
        if type(item) == 'table' then
            if lf.isObj(item) and item:__is('col') then
                item = item:all()
            end
            if depth == 1 then
                tmp = _M.mergeList(ret, item)
            else
                tmp = _M.mergeList(ret, _M.flatten(item, depth - 1))
            end

            return tmp
        else
            ret[#ret+1] = item
        end

        return ret
    end}

    result = _M.reduce(tbl, cb, result)
     
    return result
end

function _M.clone(tbl, deep)

    local newTbl = {}
    local len = #tbl

    if len > 0 then
        if not deep then
            for i, v in ipairs(tbl) do 
                newTbl[i] = v
            end
        else
            for i, v in ipairs(tbl) do 
                if type(v) == 'table' then
                    newTbl[i] = _M.clone(v, deep)
                else
                    newTbl[i] = v
                end
            end
        end
    elseif next(tbl) then
        if not deep then
            for k, v in pairs(tbl) do
                newTbl[k] = v
            end
        else
            for k, v in pairs(tbl) do
                if type(v) == 'table' then
                    newTbl[k] = _M.clone(v, deep)
                else
                    newTbl[k] = v
                end
                
            end
        end
    end

    return newTbl
end

function _M.copyScalar(tbl)

    local ret = {}
    for k, v in pairs(tbl) do
        if lf.isScalar(v) then
            ret[k] = v
        end
    end

    return ret
end

function _M.listToDict(list)

    local dict = {}
    for _, v in ipairs(list) do
        dict[v] = v
    end

    return dict
end

_M.l2d = _M.listToDict

function _M.keys(tbl)

    local keys = {}

    if next(tbl) then
        for k, _ in pairs(tbl) do
            tapd(keys, k)
        end
    end

    return keys
end

function _M.values(tbl)

    local values = {}

    if #tbl > 0 then
        for _, v in ipairs(tbl) do
            tapd(values, v)
        end
    elseif next(tbl) then
        for _, v in pairs(tbl) do
            tapd(values, v)
        end
    end

    return values
end

function _M.equal(tbl1, tbl2)

    return lf.isEqual(tbl1, tbl2)
end

_M.eq = _M.equal

function _M.just(tbl, value)

    local len = #tbl

    if len == 1 then
        if tbl[1] == value then 
            return true
        else
            return false
        end
    elseif len > 1 then
        return false
    elseif next(tbl) then
        local i = 0 
        local has = false
        for k, v in pairs(tbl) do
            i = i + 1
            if i > 1 then return false end
            if v == value then has = true end
        end

        return has
    else
        return false
    end
end

function _M.isAssoc(tbl)

    local ret = true

    local i = 0

    if #tbl > 0 then
        tsort(tbl)
        for k, v in ipairs(tbl) do
            i = i + 1
            if k ~= i then return true end
        end
        for k, v in pairs(tbl) do
            if type(k) ~= 'number' then
                return true
            end
        end

        ret = false
    end

    return ret
end

function _M.combine(keys, values)

    local ret = {}
    local len = #keys
    if len == 0 then return ret end
    if len ~= #values then return ret end

    local k, v
    for i = 1, len do
        k, v = keys[i], values[i]
        ret[k] = v
    end

    return ret
end

function _M.filter(tbl, cb, flag)

    flag = flag or 0
    local ret = {}
    local t
    cb = cb or lf.notEmpty
    
    local isList = lf.isList(tbl)

    for k, v in each(tbl) do
        if flag == 0 then
            t = cb(v, k)
        elseif flag == 1 then
            t = cb(k, v)
        end
        if t then
            if isList then
                tapd(ret, v)
            else
                ret[k] = v
            end
        end 
    end

    return ret
end

function _M.where(tbl, callback)

    return _M.filter(tbl, callback, 1)
end

function _M.diff(tbl1, ...)

    local tempTbl, allComps = {}, mergeTbls(...)
    if #tbl1 > 0 then
        for _, v in ipairs(tbl1) do
            if not allComps[v] then
                tapd(tempTbl, v)
            end
        end
    elseif next(tbl1) then
        for k, v in pairs(tbl1) do
            if not allComps[v] then
                tempTbl[k] = v
            end
        end
    end

    return tempTbl
end

function _M.diffKey(tbl1, ...)

    local tempTbl, allComps = {}, _M.mergeDict(...)

    if next(tbl1) then
        for k, v in pairs(tbl1) do
            if not allComps[k] then
                tempTbl[k] = v
            end
        end
    end

    return tempTbl
end

function _M.reject(tbl, callback)

    if not lf.isFunc(callback) then
        local value = callback
        callback = function(item)
        
            return item == value
        end
    end

    local ret = {}
    local isList = (#tbl > 0)
    
    for k, v in pairs(tbl) do
        if not callback(v, k) then
            if isList then
                tapd(ret, v)
            else
                ret[k] = v
            end
        end
    end

    return ret
end

function _M.muiltiAppend(tbl, ...)
    
    local args = {...}
    local value = _M.pop(args)

    local node = tbl
    for _, key in ipairs(args) do
        if not node[key] then
            node[key] = {}
        end
        node = node[key]
    end

    tapd(node, value)
end

_M.mapd = _M.muiltiAppend

function _M.wrap(value)

    if type(value) ~= 'table' then
        value = {value}
    end

    return value
end

function _M.remove(tbl, offset, length)

    if not tbl then return end
    local len = #tbl
    if len == 0 then return end

    local first, last = utils.getRange(len, offset, length)

    if first <= len then
        for i = last, first, -1 do
            tremove(tbl, i)
        end
    end

    return tbl
end

function _M.replace(...)

    local tbls = {...}
    local ret = {}

    for _, tbl in ipairs(tbls) do
        for k, v in pairs(tbl) do
            ret[k] = v
        end
    end

    return ret
end

function _M.collapse(tbls)

    local values
    local results = {}
    for _, values in pairs(tbls) do
        if lf.isTbl(values) then
            if lf.isObj(values) and values:__is('col') then
                values = values:all()
            end
            results = _M.merge(results, values)
        end
    end
    
    return results
end

function _M.range(low, high, step)

    step = step or 1
    local ret = {}
    for i = low, high, step do
        tapd(ret, i)
    end

    return ret
end

function _M.getValue(value)

    if type(value) == 'function' then
        return value()
    else
        return value
    end
end

function _M.getItem(tbl, key)

    if not lf.isTbl(tbl) then
        return
    end

    local t
    if lf.isList(tbl) then
        if type(key) ~= 'number' then
            key = cint(key)
        end
    else
        if type(key) ~= 'string' then
            key = cstr(key)
        end
    end

    t = tbl[key]
    if type(t) ~= 'nil' then
        return t, true
    end
end

function _M.dataGet(target, key, default)

    local t, hasValue
    local result

    if not key then
        
        return target
    end
    key = lf.isTbl(key) and _M.clone(key) or Str.split(key, '.')
    local segment = _M.shift(key)
    while segment do
        if segment == '*' then
            if not lf.isTbl(target) then
                
                return _M.getValue(default)
            elseif lf.isObj(target) and target:__is('col') then
                target = target:all()
            end
            result = _M.pluck(target, key)
            
            return _M.inList(key, '*') and _M.collapse(result) or result
        end
        t, hasValue = _M.getItem(target, segment)
        if lf.isTbl(target) and hasValue then
            target = t
        else
            return _M.getValue(default)
        end

        segment = _M.shift(key)
    end
    
    return target
end

function _M.dataSet(target, key, value, overwrite, parent, lastKey)

    overwrite = lf.needTrue(overwrite)
    local segments = lf.isTbl(key) and key or Str.split(key, '.')
    local segment = _M.shift(segments)

    if segment == '*' then
        if not lf.isTbl(target) then
            if parent and lastKey then
                target = {}
                parent[lastKey] = target
            end
        end

        if #segments > 0 then
            for k, inner in pairs(target) do
                _M.dataSet(inner, _M.clone(segments), value, overwrite, target, k)
            end
        elseif overwrite then
            for k, inner in pairs(target) do
                target[k] = value
            end
        end
    elseif lf.isObj(target) and target:__is('col') then
        if #segments > 0 then
            if not target(segment) then
                target:add({}, segment)
            end
            _M.dataSet(target(segment), segments, value, overwrite, target, segment)
        elseif overwrite or not target(segment) then
            target:add(value, segment)
        end
    elseif lf.isTbl(target) then
        if #segments > 0 then
            if not _M.exists(target, segment) then
                target[segment] = {}
            end
            _M.dataSet(target[segment], segments, value, overwrite, target, segment)
        elseif overwrite or not _M.exists(target, segment) then
            target[segment] = value
        end
    else
        if parent and lastKey then
            target = {}
            parent[lastKey] = target
        end
        if #segments > 0 then
            _M.dataSet(target[segment], segments, value, overwrite, target, segment)
        elseif overwrite then
            target[segment] = value
        end
    end
    
    return target
end

function _M.dataFill(target, key, value)

    return _M.dataSet(target, key, value, false)
end

function _M.chunk(tbl, size)

    local ret = {}
    local len = #tbl

    if not size or size < 1 then
        return {}
    end

    if size >= len then
        return _M.clone(tbl)
    else
        local chunk
        for i = 1, len do
            if math.mod(i, size) == 1 or (size == 1) then
                chunk = {}
                tapd(ret, chunk)
            end
            tapd(chunk, tbl[i])
        end
    end

    return ret
end

function _M.slice(tbl, offset, length)

    local ret = {}
    if not tbl then return ret end
    local tblLen = #tbl
    if tblLen == 0 then return ret end

    local first, last = utils.getRange(tblLen, offset, length)

    if first <= tblLen then
        for i = first, last do
            tapd(ret, tbl[i])
        end
    end

    return ret
end

function _M.column(tbl, columnKey, indexKey)

    local ret = {}
    local t

    for _, item in ipairs(tbl) do
        t = item[columnKey]
        if indexKey then
            ret[item[indexKey]] = t
        else
            tapd(ret, t)
        end
    end

    return ret
end

return _M

