
local _M = {
    _cls_ = ''
}

local mt = { __index = _M }

local package = package
local type = type

local isSeeded = false

local dtBase = require('lxlib.resty.date')
local Str = require('lxlib.base.str')
local jsonBase = require('lxlib.json.base')
local utils = require('lxlib.base.utils')
local filterVar = require('lxlib.base.common.filterVar')

local stDtPat = "%Y-%m-%d %H:%M:%S"
local ssub, sgsub, sfind, slower= string.sub, string.gsub, string.find, string.lower
local sfmt, supper, sbyte, slen = string.format, string.upper, string.byte, string.len
local sreverse = string.reverse
local rematch = ngx.re.match
local ceil, floor = math.ceil, math.floor

function _M.ensureSeeded()
    
    if not isSeeded then
        local workerId = ngx.worker.pid()
        ngx.update_time()
        local t = ngx.now() * 1000 
        local st = sreverse(ssub(t, 6, -1))
     
        st = workerId .. st

        t = tonumber(st)

        math.randomseed(t)

        isSeeded = true
    end
end

function _M.isStr(var)

    return type(var) == 'string'
end

function _M.isTbl(var)

    return type(var) == 'table'
end

_M.isArr = _M.isTbl

function _M.isDict(var)

    if type(var) == 'table' then
        if next(var) then
            if table.maxn(var) == 0 then
                return true
            end
        end
    end

    return false
end

function _M.isList(var, strict)

    if type(var) == 'table' then
        if next(var) then
            local max = table.maxn(var)
            if max > 0 then
                if not strict then
                    return true
                else
                    if #var == max then
                        return true
                    end
                end
            end
        end
    end

    return false
end

function _M.isFunc(var)

    return type(var) == 'function'
end

_M.isFun = _M.isFunc

function _M.isCallable(var)

    local vt = type(var)
    local obj, method

    if vt == 'function' then
        return true
    elseif vt == 'table' then
        if #var > 0 then
            obj, method = var[1], var[2]
            local fn = obj[method]
            if type(fn) == 'function' then
                return true
            end
        elseif next(var) then
            local mt = getmetatable(var)
            return mt.__call and true or false
        end
    end

    return false
end

function _M.isNum(var)

    return type(var) == 'number'
end

function _M.isInt(var)

    if type(var) ~= 'number' then
        return false
    end

    return var % 1 == 0
end

function _M.isFloat(var)

    if type(var) ~= 'number' then
        return false
    end

    return var % 1 ~= 0
end

function _M.isNil(var)

    return type(var) == 'nil'
end

function _M.notNil(var)

    return type(var) ~= 'nil'
end

function _M.isObj(var)

    if type(var) == 'table' then
        return var.__cls and true or false
    else
        return false
    end
end

function _M.isFalse(var)
    
    if not var then
        return type(var) == 'boolean' and true or false
    else
        return false
    end
end

function _M.isTrue(var)
    if var then
        return type(var) == 'boolean' and true or false
    end
end

function _M.isBool(var)

    return type(var) == 'boolean'
end

function _M.isFalseStr(var)

    if type(var) == 'string' then
        return slower(var) == 'false'
    end
end

function _M.isTrueStr(var)

    if type(var) == 'string' then
        return slower(var) == 'true'
    end
end

function _M.isNilStr(var)

    if type(var) == 'string' then
        return slower(var) == 'nil'
    end
end

function _M.isNumStr(var)

    return tonumber(var) and true or false
end

function _M.isIntStr(var)

    return Str.allNum(var)
end

function _M.isFloatStr(var)

    var = tonumber(var)
    if not var then return false end

    return _M.isFloat(var)
end

function _M.isBoolStr(var)

    if type(var) == 'string' then
        local t = slower(var)
        if t == 'true' or t == 'false' then
            return true
        else
            return false
        end
    end
end

function _M.strToBool(var)

    if type(var) == 'string' then
        var = slower(var)
        if var == 'true' then return true end
        if var == 'false' then return false end
        if var == 'nil' or var == '' then return nil end

        return true
    else
        return true
    end
end

function _M.isEmpty(var)

    if not var then return true end

    local vt = type(var)
    if vt == 'table' then
        local t = next(var)
        if type(t) == 'nil' then
            return true
        end
    elseif vt == 'string' then
        local varLen = slen(var)
        if varLen == 0 then
            return true
        elseif varLen == 1 then
            if var == '0' then
                return true
            end
        end
    elseif vt == 'number' then
        if var == 0 then
            return true
        end
    end

    return false
end

_M.empty = _M.isEmpty

function _M.notEmpty(var)

    return not _M.isEmpty(var)
end

function _M.neverEmpty(var)

    if _M.isEmpty(var) then
        return nil
    else
        return var
    end
end

function _M.isEqual(var1, var2, strict)

    local vt1, vt2 = type(var1), type(var2)
    if strict and vt1 ~= vt2 then
        return false
    end

    if vt1 == 'table' and vt2 == 'table' then
        return _M.isTblEqual(var1, var2)
    else
        var1 = tostring(var1)
        var2 = tostring(var2)

        return var1 == var2
    end
end

_M.eq = _M.isEqual

function _M.isTblEqual(tbl1, tbl2)
    
    local ret = false

    local t
    if #tbl1 > 0 and #tbl1 == #tbl2 then
        ret = true
        for k, v in ipairs(tbl1) do
            t = tbl2[k]
            if _M.isNil(t) then return false end
            if not _M.isEqual(v, t) then return false end
        end
    elseif next(tbl1) and next(tbl2) then
        local len1, len2 = 0, 0
        for k, v in pairs(tbl1) do
            t = tbl2[k]
            if _M.isNil(t) then return false end
            if not _M.isEqual(v, t) then return false end
            len1 = len1 + 1
        end
        for k, v in pairs(tbl2) do
            len2 = len2 + 1
        end

        if len1 == len2 then ret = true end
    elseif #tbl1 == #tbl2 then
        ret = true
    end
 
    return ret
end

function _M.isJsonable(var)

    local ret = false

    if var then
        local vt = type(var)
        if vt == 'table' then
            if var.__cls then
                if var:__is 'jsonable' then
                    ret = true
                end
            end
        end
    end

    return ret
end

function _M.isRenderable(var)

    local ret = false

    if var then
        local vt = type(var)
        if vt == 'table' then
            if var.__cls then
                if var:__is 'renderable' then
                    ret = true
                end
            end
        end
    end

    return ret
end

function _M.isAble(var, clsType)

    local ret = false

    if var then
        local vt = type(var)
        if vt == 'table' then
            if var.__cls then
                if var:__is(clsType) then
                    ret = true
                end
            end
        end
    end

    return ret
end

_M.isA = _M.isAble

function _M.getAble(var, ...)

    local ret = false

    if var then
        local vt = type(var)
        if vt == 'table' then
            if var.__cls then
                local ables = _M.needArgs(...)
                for _, able in ipairs(ables) do
                    if type(var[able]) == 'function' then
                        return able
                    end
                end
            end
        end
    end

    return ret
end

function _M.runAble(var, ...)

    local able = _M.getAble(var, ...)

    if able then
        local func = var[able]

        return func(var, ...)
    end
end

function _M.asTbl(var)
    
    if type(var) ~= 'table' then
        var = {var}
    end

    return var
end

function _M.toBool(var)
    
    return var and true or false
end

function _M.toInt(var, default)

    default = default or 0
    local num = tonumber(var)
    if not num then
        return default
    end

    if not _M.isInt(var) then
        num = floor(num)
    end

    return num
end

function _M.isset(var)

    return var and true or type(var) ~= 'nil'
end

function _M.needTrue(var)
    
    if type(var) == 'nil' then
        return true
    else
        return var
    end
end

function _M.needFalse(var)

    if type(var) == 'nil' then
        return false
    else
        return var
    end
end

function _M.needList(var)

    local vt = type(var)
    if vt == 'table' then
        if #var > 0 then
            return var
        elseif next(var) then
            local t = var.__cls
            if t and t == 'col' and var.asList then
                return var:all()
            end
            return {var}
        else
            return {}
        end
    else
        return {var}
    end
end

function _M.toStr(var)

    if type(var) == 'table' then
        return jsonBase.encode(var)
    else
        return tostring(var)
    end
end

function _M.jsen(tbl)

    return jsonBase.encode(tbl)
end

function _M.jsde(s)

    return jsonBase.decode(s)
end

function _M.dtFmt(dv, pattern)

    local ok, dt = pcall(dtBase, dv)
    if not ok then return end
    
    if not pattern then 
        pattern = stDtPat
    end

    local dtStr = dt:fmt(pattern)

    return dtStr
end

function _M.dtAdd(unitType, num, dv, pattern)

    if not dv then
        dv = ngx.now()
    end
    local dt = dtBase(dv)

    if unitType == 'y' then
        dt:addyears(num)
    elseif unitType == 'm' then
        dt:addmonths(num)
    elseif unitType == 'w' then
        dt:adddays(num * 7)
    elseif unitType == 'd' then
        dt:adddays(num)
    elseif unitType == 'h' then
        dt:addhours(num)
    elseif unitType == 'n' then
        dt:addminutes(num)    
    elseif unitType == 's' then
        dt:addseconds(num)
    end

    local pat = pattern or stDtPat
    return dt:fmt(pat)
end

function _M.timestamp(needMilliseconds, refresh, timezone)
    
    if refresh then
        ngx.update_time()
    end

    if needMilliseconds then
        local tstr = ngx.now()

        return tstr * 1000
    else
        return ngx.time()
    end
end

_M.time = _M.timestamp

function _M.dt2ts(datetime)
 
    local ok, t = pcall(dtBase, datetime)
    if ok then 
        local tab = {
            year = t:getyear(), month = t:getmonth(), 
            day = t:getday(), hour = t:gethours(),
            min  = t:getminutes(), sec = t:getseconds()
         }

        return os.time(tab)
    else
        return 0
    end
end

function _M.now(refresh)

    if refresh then
        ngx.update_time()
    end

    return ngx.now()
end

function _M.datetime(format, time)

    if not format and not time then 
        return ngx.localtime()
    end

    format = format or '%Y-%m-%d %H:%M:%S'
    time = time or os.time()
    
    return os.date(format, time)
end

_M.date = _M.datetime

function _M.cost(callback, ...)

    local t1 = _M.timestamp(true, true)
    callback(...)
    local t2 = _M.timestamp(true, true)

    return t2 - t1
end

function _M.md5(str)

    if ngx then
        return ngx.md5(str)
    end
end

function _M.base64En(s)

    return ngx.encode_base64(s)
end

function _M.base64De(s)
    
    return ngx.decode_base64(s)
end

function _M.base64urlEn(s)

    return Str.rtrim(Str.tr(_M.base64En(s), '+/', '-_'), '=')
end

function _M.base64urlDe(s)

    return _M.base64De(Str.pad(Str.tr(s, '-_', '+/'), slen(s) % 4, '='))
end

function _M.escape(w)

    local pattern = "[^%w%d%._%-%* ]"  
    local s = sgsub(w, pattern, function(c)  
        local c = sfmt("%%%02X", sbyte(c))  
        return c  
    end)  
    s = sgsub(s, " ", "+")  
    return s  
end

function _M.uriEncode(s)

    return ngx.escape_uri(s)
end

_M.uriencode = _M.uriEncode
_M.urlencode = _M.uriEncode

function _M.uriDecode(s)

    return ngx.unescape_uri(s)
end

_M.uridecode = _M.uriDecode
_M.urldecode = _M.uriDecode

function _M.randnum(min, max)

    _M.ensureSeeded()

    local ret = 0 
    if min and max then
        ret = math.random(min,max)
    elseif min then
        ret = math.random(min)
    else
        ret = math.random()
    end
    
    return ret
end

_M.random = _M.randnum
_M.rnd = _M.randnum
_M.rand = _M.randnum

function _M.rands(min, max, num)

    _M.ensureSeeded()

    local range = {}
    for i = 1, max - min + 1 do 
        range[i] = min + i - 1
    end

    local ret = {}
    local subscript, temp
    for i = 1, num do
        subscript = math.random(1, #range - 1)
        temp = range[subscript]
        range[subscript] = range[#range]
        table.remove(range, #range)
        ret[i] = temp
    end

    return ret
end

function _M.guid(formatType, isUcase)
    
    _M.ensureSeeded()

    local guid
    local fmtType = formatType or "N"
    fmtType = supper(fmtType)

    local seed = {'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f'}
    local tb = {}
    for i = 1, 32 do
        table.insert(tb, seed[math.random(1,16)])
    end
    local sid = table.concat(tb)
    if fmtType == 'N' then
        guid = sid
    elseif  fmtType == 'P' or fmtType == 'B' then
        guid = sfmt('%s%s%s%s%s'),
                    ssub(sid, 1, 8),
                    ssub(sid, 9, 12),
                    ssub(sid, 13, 16),
                    ssub(sid, 17, 20),
                    ssub(sid, 21, 32)
        if fmtType == 'P' then
            guid = '('..guid..')'
        end
    else
        guid = sid
    end

    if isUcase then 
        guid = supper(guid)
    end

    return guid
end

function _M.split(s, separator, max)
    
    return Str.split(s, separator, max)
end

function _M.trim(s, charList)
    return Str.trim(s, charList)
end

function _M.ltrim(s, charList)

    return Str.ltrim(s, charList)
end

function _M.rtrim(s, charList)

    return Str.rtrim(s, charList)
end
 
function _M.getArgs(...)

    return {...}, select('#', ...)
end

function _M.copyArgs(...)
    local ret = {}
    local len = select('#', ...)
    for i = 1, len do
        ret[i] = select(i, ...)
    end

    return ret, len
end

function _M.mustArgs(...)

    local argsLen, args = select('#', ...), {...}
    local p1 = args[1]
    local p1Type = type(p1)

    if p1Type == 'table' then
        return p1, 1
    else
        return false, args, argsLen
    end
end

_M.needArgs = utils.needArgs

function _M.use(args, cb)
    
    if not cb then
        cb = args[1]
    end

    local priEnv = getfenv(cb)
    for k, v in pairs(args) do
        priEnv[k] = v
    end
    
    setfenv(cb, priEnv)

    return cb
end

function _M.call(target, ...)
    
    local typ = type(target)

    if typ == 'function' then
        
        return target(...)
    elseif typ == 'table' then
        local obj, method = target[1], target[2]
        if not obj then
            error('obj is nil')
        end

        local func = obj[method]

        if type(func) == 'function' then
            return func(obj, ...)
        else
            error('method:' .. tostring(method) .. ' not exists')
        end
    end

end

function _M.callArgs(target, ...)

    local typ = type(target)
    local func
    local args = {...}
    local ret = {}
    local obj, method

    if typ == 'table' then
        obj, method = target[1], target[2]
        if not obj then
            error('obj is nil')
        end

        func = obj[method]

        if type(func) == 'function' then
        else
            error('method:' .. tostring(method) .. ' not exists')
        end
    end
 
    local len = #args

    if len == 1 then
        return func(obj, args[1])
    elseif len == 2 then
        return func(obj, args[1]), func(obj, args[2])
    elseif len == 3 then
        return func(obj, args[1]), func(obj, args[2]), func(obj, args[3])
    elseif len == 4 then
        return func(obj, args[1]), func(obj, args[2]), func(obj, args[3]), func(obj, args[4])
    elseif len == 5 then
        return func(obj, args[1]), func(obj, args[2]), func(obj, args[3]), func(obj, args[4]), func(obj, args[5])
    elseif len == 6 then
        return func(obj, args[1]), func(obj, args[2]), func(obj, args[3]), func(obj, args[4]), func(obj, args[5]), func(obj, args[6])
    elseif len == 7 then
        return func(obj, args[1]), func(obj, args[2]), func(obj, args[3]), func(obj, args[4]), func(obj, args[5]), func(obj, args[6]), func(obj, args[7])
    end
end

function _M.isIn(var, ...)

    local args = _M.needArgs(...)

    return _M.isInTbl(var, args)
end

function _M.isInTbl(var, tbl)

    local vt = type(var)
    for _, v in ipairs(tbl) do
        if type(v) == vt then
            if var == v then
                return true
            end
        end
    end

    return false
end

function _M.prequire(path)

    local ok, ret = pcall(require, path) 
    if not ok then return nil, ret end
    
    return ret
end

function _M.import(bagName, subBag)

    if sfind(bagName, '@') then
        bagName, subBag = Str.divide(bagName, '@')
    end

    local bag = require(bagName)
    if type(bag) ~= 'table' then 
        error('invalid bag [' .. bagName .. ']')
    end

    if bag._clses_ then
        if not bag.__path then
            bag.__path = bagName
        end

        if not subBag then
            return bag
        end
         
        return _M.importFrom(bag, subBag)
    end

    bag.__name = Str.last(bagName, '.')

    local cls = bag._cls_
    local clsed = bag.__cls
    if cls and not clsed then
        if slen(cls) > 0 then
            if ssub(cls, 1, 1) == '@' then
                clsed = ssub(cls, 2)
            else
                clsed = bagName .. cls
            end
            bag.__cls = clsed
        else
            clsed = bagName
            bag.__cls = clsed
        end
    end

    return bag
end

function _M.importFrom(path, bagName)

    local mod
    if type(path) == 'table' then
        mod = path
    else
        mod = require(path)
    end

    if not mod then
        error('invalid path [' .. path .. ']')
    end

    local bag = mod[bagName]

    if not bag then
        error('bag [' .. bagName .. '] invalid')
    end

    local clsed = bag.__cls
    bag.__name = bagName
    local cls = bag._cls_
    local clsed = bag.__cls
    if cls and not clsed then
        if slen(cls) > 0 then
            if ssub(cls, 1, 1) == '@' then
                clsed = ssub(cls, 2)
            else
                clsed = mod.__path .. cls
            end
            bag.__cls = clsed
        else
            clsed = mod.__path .. '.' .. bagName
            bag.__cls = clsed
        end
    end

    return bag
end

function _M.isWin()
    
    return package.config:sub(1,1) == '\\'
end

function _M.isSys64()
    
end

function _M.run(cmd)
 
    local pf = io.popen(cmd)
    if pf then
        local ret = pf:read('*all')
        pf:close()

        return ret
    else
        return 'popen fail'
    end

end

function _M.value(var)

    if type(var) == 'function' then
        return var()
    else
        return var
    end
end

function _M.dostr(luacode, env)

    local bitCode = assert(loadstring(luacode))
    if env then
        setfenv(bitCode, env)
    end

    return bitCode()
end

function _M.httpBuildQuery(data, prefix, separator, encType)

    prefix = prefix or ''
    separator = separator or '&'
    encType = encType or 1

    local ret = {}

    for k, v in pairs(data) do
        if encType == 1 then
            v = _M.escape(v)
        elseif encType == 2 then
            v = _M.urlencode(v)
        else
            error('unsupported encType:' .. encType)
        end
        tapd(ret, prefix .. k .. '=' .. v)
    end

    ret = Str.join(ret, separator)

    return ret
end

_M.hbq = _M.httpBuildQuery
_M.rawurlencode = _M.urlencode
_M.rawurldecode = _M.urldecode

function _M.parseUrl(url, option)

    return filterVar.parseUrl(url, option)
end

function _M.parseStr(s)

    local ret = ngx.decode_args(s)

    return ret
end

function _M.isSubClsOf(cls, parent)

    local lx = require('lxlib')
    local app = lx.app()

    return app:isSubClsOf(cls, parent)
end

_M.hex = utils.toHex
_M.atoi = utils.atoi
_M.fromHex = utils.fromHex

function _M.sha1(s)

    s = tostring(s)
    local Sha1 = require('resty.sha1')
    local obj = Sha1:new()
    obj:update(s)
    s = obj:final()

    return _M.hex(s)
end

function _M.filter(var, filter, options)

    return filterVar.filter(var, filter, options)
end

function _M.isScalar(var)

    local vt = type(var)

    if vt == 'string' or vt == 'number' or vt == 'boolean' then
        return true
    else
        return false
    end
end

function _M.clsBaseName(s)

    return Str.last(s, '.')
end

_M.clsBase = _M.clsBaseName

_M.htmlentities = utils.htmlentities

function _M.needCls(var)

    local vt = type(var)
    if vt == 'string' then
        return var
    elseif vt == 'table' then
        var = var.__cls
        if var then
            return var
        end
    end

    error('invalid cls')
end

function _M.try(callback)

    local tErr,tTrace
    local ok = xpcall((function() 
            callback()
        end), 
        function(_err)
            tErr = _err
            tTrace = debug.traceback('', 2)
        end
    )

    return ok, tErr, tTrace
end

function _M.toEach(var)

    if var:__is('iteratable') then
        var = var:getIterator()
    end

    if not var:__is('iterator') then
        error('is not a iterator')
    end

    var:rewind()
    local k, v
    local inited = false

    return function()
        if inited then
            var:next()
        end
        if var:valid() then
            v = var:current()
            k = var:key()
            inited = true

            return k, v
        else
            return nil
        end
    end
end

function _M.each(var)

    local cls = var.__cls

    if cls then
        if var:__is('eachable') then

            return var:toEach()
        else
            error('can not loop ' .. cls)
        end
    else
        if #var > 0 then
            return ipairs(var)
        else
            return pairs(var)
        end
    end
end

function _M.eachToArr(var)

    local ret = {}
    for k, v in _M.each(var) do
        ret[k] = v
    end

    return ret
end

local packer

function _M.pack(data)

    local lx = require('lxlib')
    if not packer then
        packer = lx.new('msgPack') 
    end

    return packer:pack(data)
end

function _M.unpack(value)
    
    local lx = require('lxlib')
    if not packer then
        packer = lx.new('msgPack') 
    end

    return packer:unpack(value)
end

return _M

