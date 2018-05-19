
local _M = {
    _cls_ = ''
}

local mt = { __index = _M }

local utils = require('lxlib.base.utils')
local deformation = require('lxlib.base.common.deformation')
local utf8Utils = require('lxlib.base.common.utf8')

local sfind, ssub, supper, slower, smatch, sgmatch, sgsub =
    string.find, string.sub, string.upper, string.lower, string.match, string.gmatch, string.gsub

local sfmt, slen, schar, sbyte = string.format, string.len, string.char, string.byte
local sreverse, srep = string.reverse, string.rep

local mabs, mfloor, mceil = math.abs, math.floor, math.ceil

local tinsert, tconcat, tremove = table.insert, table.concat, table.remove
local rematch, resub, regsub, refind, resplit, regmatch =
    ngx.re.match, ngx.re.sub, ngx.re.gsub, ngx.re.find, ngx.re.split, ngx.re.gmatch

local studlyCache       = {}
local snakeCache        = {}
local camelCache        = {}
local pregQuoteCache    = {}
local lregQuoteCache    = {}

do
    for k, v in pairs(string) do
        _M[k] = v
    end
end

_M.utf8 = utf8Utils

local function tapd(t, v)
    t[#t+1] = v
end

local function escape(s)
    return (sgsub(s, '[%-%.%+%[%]%(%)%$%^%%%?%*]','%%%1'))
end

local function _strip(s, left, right, chrs)

    local i1,i2
    if not chrs then
        chrs = '[%s]'
    else
        chrs = '['..escape(chrs)..']'
    end
    if left then
        i1,i2 = sfind(s,'^'..chrs..'*')
        if i2 >= i1 then
            s = ssub(s, i2 + 1)
        end
    end
    if right then
        i1,i2 = sfind(s, chrs..'*$')
        if i2 >= i1 then
            s = ssub(s, 1, i1-1)
        end
    end

    return s
end

local function _split(s, delim, max, notplain)

    local plain = not notplain

    if type(delim) ~= "string" or slen(delim) == 0 then
        return
    end

    local start = 1
    local t = {}
    local count = 0
    while true do
        local pos,  pos_end = sfind(s, delim, start, plain) -- plain find
        if not pos then
            break
        end
        count = count + 1
        if max and max > 0 and count > max - 1 then
            tinsert(t, ssub(s, start))
            return t
        end
        tinsert(t, ssub(s, start, pos - 1))
        start = pos_end + 1
    end

    tinsert(t, ssub(s, start))

    if max and max < 0 then
        count = #t + max
        local tt = {}
        for i = 1, count do
            tt[i] = t[i]
        end
        t = tt
    end

    return t
end

_M.fmt = _M.format

function _M.ltrim(s, charlist)

    return _strip(s, true, false, charlist)
end
 
function _M.rtrim(s, charlist)

    return _strip(s, false, true, charlist)
end

function _M.trim(s, charlist)

    return _strip(s, true, true, charlist)
end

function _M.replace(s, search, replace, plain)

    local slist, count, t
    local ret, lookups = {}, {}

    local vt = type(search)
    local rtype = type(replace)
    if vt == 'table' then
        if rtype == 'table' then
            for i, v in ipairs(search) do
                lookups[v] = replace[i] or ''
            end
        elseif rtype == 'string' then
            for i, v in ipairs(search) do
                lookups[v] = replace
            end
        elseif rtype == 'nil' then
            if #search == 0 and next(search) then
                lookups = search
            end
        end
    else
        lookups[search] = replace or ''
    end

    vt = type(s)
    if vt == 'string' then
        slist = {s}
    elseif vt == 'table' then
        slist = s
    end

    for _, v in ipairs(slist) do
        for k, vv in pairs(lookups) do
            if plain then
                k = escape(k)
            end
            v = sgsub(v, k, vv)
        end
        tapd(ret, v)
    end

    if #ret == 1 then
        return ret[1]
    else
        return ret
    end
end

function _M.replaceArray(subject, search, replace)

    for _, value in pairs(replace) do
        subject = _M.replaceFirst(subject, search, value)
    end
    
    return subject
end

function _M.replaceFirst(subject, search, replace)

    if slen(search) == 0 then
        return subject
    end
    local position = sfind(subject, search)
    if position then
        
        return _M.substrReplace(subject, replace, position, slen(search))
    end
    
    return subject
end

function _M.replaceLast(subject, search, replace)

    local position = _M.rpos(subject, search)
    if position then
        
        return _M.substrReplace(subject, replace, position, slen(search))
    end
    
    return subject
end

function _M.substrReplace(pSubject, pReplace, pStart, pLength)

    local searchList = utils.needList(pSubject)
    local replaceList = utils.needList(pReplace)
    local lengthList = utils.needList(pLength)

    if #replaceList < #searchList then
        for i = #replaceList + 1, #searchList do
            replaceList[i] = replaceList[1]
        end
    end
    if #lengthList < #searchList then
        for i = #lengthList + 1, #searchList do
            lengthList[i] = lengthList[1]
        end
    end

    local ret = {}
    local result
    local search, replace, start, length
    local over, searchLen, beginning, middle, ending
    for i, s in ipairs(searchList) do
        start = pStart
        search = searchList[i]
        replace = replaceList[i]
        length = lengthList[i]
        searchLen = slen(search)
        start, over = utils.getRange(searchLen, start, length)
        beginning = ssub(search, 1, start - 1)
        ending = ssub(search, over + 1)
        middle = replace or ''
        result = beginning .. middle .. ending
        tapd(ret, result)
    end

    if #ret > 1 then
        return ret
    else
        return ret[1]
    end
end

function _M.tr(s, search, replace)

    local searchType, replaceType = type(search), type(replace)

    if searchType == 'string' and replaceType == 'string' then
        local searchSize, replaceSize = slen(search), slen(replace)
        local minSize
        if searchSize > replaceSize then
            minSize = replaceSize
            search = ssub(search, 1, minSize)
        elseif searchSize > replaceSize then
            minSize = searchSize
            replace = ssub(replace, 1, minSize)
        else
            minSize = searchSize
        end

        local lookups = {}
        local k, v
        for i = 1, minSize do
            k = ssub(search, i, i)
            v = ssub(replace, i, i)
            lookups[k] = v
        end
        local ret = {}
        local t
        for i = 1, slen(s) do
            t = ssub(s, i, i)
            v = lookups[t]
            if v then t = v end
            tapd(ret, t)
        end

        return tconcat(ret)
    elseif searchType == 'table' then
        local maxlen = 0
        local minlen = 1024 * 128
        if not next(search) then
            return s
        end
        local len
        for k, v in pairs(search) do
            len = slen(k)
            if len > 0 then
                if len > maxlen then
                    maxlen = len
                end
                if len < minlen then
                    minlen = len
                end
            end
        end
        len = slen(s)
        local pos = 0
        local result = ''
        local found, key
        local key1

        while pos < len do
            if pos + maxlen > len then
                maxlen = len - pos
            end
            found = false
            key = ''
            for i = 1, maxlen + 1 do
                key = key .. ssub(s, i + pos, i + pos)
            end
            for i = maxlen + 1,minlen - 1, -1 do
                key1 = ssub(key, 1, i)
                
                if search[key1] then
                    result = result .. search[key1]
                    pos = pos + i
                    found = true
                    break
                end
            end
            if not found then
                pos = pos + 1
                result = result .. ssub(s, pos, pos)
            end
        end

        return result
    end

end

_M.strtr = _M.tr

function _M.split(s, delim, max, notplain)

    if not delim then
        delim = ','
    end

    return _split(s, delim, max, notplain)
end

function _M.divide(s, delim, notplain)

    local plain = not notplain

    if not delim then
        delim = ','
    end

    local i, j = sfind(s, delim, nil, plain)

    if i then
        local left, right
        left = ssub(s, 1, i - 1)
        right = ssub(s, j + 1)

        return left, right
    else
        return s
    end
end

_M.div = _M.divide

local function pairsByKeys(t)  
    local a = {}  
    for n in pairs(t) do  
        a[#a+1] = n  
    end  
    table.sort(a)  
    local i = 0  
    return function()  
        i = i + 1  
        return a[i], t[a[i]]  
    end  
end 

function _M.join(tbl, delim)
     
    local ret

    if not tbl then 
        return ''
    end
    if not delim then
        delim = ''
    end

    local ok, ret = pcall(tconcat, tbl, delim)
    if not ok then
        local t = {}
        for k, v in pairsByKeys(tbl) do
            t[#t+1] = v
        end
        ret = tconcat(t, delim)
    end
 
    return ret
end

function _M.ucfirst(s)
    local first = ssub(s,1,1)
    first = supper(first)

    return first .. ssub(s,2)
end

_M.ucFirst = _M.ucfirst

function _M.lcfirst(s)

    local first = ssub(s,1,1)
    first = slower(first)

    return first .. ssub(s,2)
end

_M.lcFirst = _M.lcfirst

function _M.ucwords(s)
    local ret = sgsub(s, '%s%w', function(v)
        return ' ' .. supper(v)
    end)

    ret = _M.ucfirst(ret)
    return ret
end

function _M.camel(s)

    local key = s
    local cached = camelCache[key]
    if cached then
        return cached
    end

    s = _M.lcfirst(_M.studly(s))
    camelCache[key] = s

    return s
end

function _M.studly(s)

    local key = s
    local cached = studlyCache[key]
    if cached then
        return cached
    end

    s = sgsub(s, '[_-]', ' ')
    s = _M.ucwords(s)
    s = sgsub(s,' ','')
    studlyCache[key] = s

    return s
end

function _M.has(s, ...)

    local args = utils.needArgs(...)

    for _, v in ipairs(args) do
        if v and slen(v) > 0 then
            if sfind(s, v) then
                return true
            end
        end
    end

    return false
end

_M.contains = _M.has

function _M.startsWith(s, starts)

    starts = utils.needList(starts)

    local pos
    for _, sign in ipairs(starts) do
        if slen(sign) > 0 then
            pos = sfind(s, sign)
            if pos == 1 then
                return true
            end
        end
    end

    return false
end

_M.startWith = _M.startsWith

function _M.endsWith(s, ends)

    ends = utils.needList(ends)

    local pos
    local signLen
    for _, sign in ipairs(ends) do
        if type(sign) ~= 'string' then
            sign = tostring(sign)
        end
        signLen = slen(sign)
        if signLen > 0 then
            if sign == ssub(s, -signLen) then
                return true
            end
        end
    end

    return false
end

_M.endWith = _M.endsWith

function _M.is(s, pattern)

    if pattern == s then
        return true
    end

    pattern = _M.lregQuote(pattern)
    pattern = sgsub(pattern, '%%%*', '.*')

    local i, j = sfind(s, pattern)

    if i == 1 and j == slen(s) then
        return true
    end

    return false
end

function _M.last(s, delim, notplain)
    
    if not s then return end
    if not sfind(s, delim) then return s end
    local segment = _M.split(s, delim, nil, notplain)

    return segment[#segment]
end

function _M.first(s, delim, notplain)
    
    if not s then return end
    if not sfind(s, delim) then return s end
    local segment = _M.split(s, delim, nil, notplain)

    return segment[1]
end

function _M.random(len)

    len = len or 16
    local ret = utils.bytes(math.ceil(len / 2))
    ret = utils.toHex(ret)
    if slen(ret) > len then
        ret = ssub(ret, 2)
    end

    return ret
end

function _M.limit(s, limit, ending)

    ending = ending or '...'
    limit = limit or 100
    local len = slen(s)
    if len <= limit then
        
        return s
    end
    local endingLen = slen(ending)
    s = ssub(s, 1, limit) .. ending

    return s
end

function _M.finish(s, cap)

    local quoted = _M.pregQuote(cap)

    return _M.rereplace(s, '(?:' .. quoted .. ')+$', '') .. cap
end

function _M.title(s)

    return (sgsub(s, '(%S)(%S*)',function(f,r)
        return supper(f) .. slower(r)
    end))
end

function _M.slug(title, separator)

    separator = separator or '-'
    
    local flip = separator == '-' and '_' or '-'
    title = _M.rereplace(title, '[' .. _M.pregQuote(flip) .. ']+', separator)
    title = _M.rereplace(slower(title), '[^' .. _M.pregQuote(separator) .. '\\pL\\pN\\s]+', '', 'jou')
    title = _M.rereplace(title, '[' .. _M.pregQuote(separator) .. '\\s]+', separator, 'jou')
    
    return _M.trim(title, separator)
end

function _M.snake(s, delimiter)

    delimiter = delimiter or '_'
    local key = s .. delimiter
    local cached = snakeCache[key]
    if cached then
        return cached
    end

    if _M.hasUpper(s) then
        local first = sbyte(ssub(s,1,1))
        local underlineFirst = first > 64 and first < 91
        s = sgsub(s, '%s', '')

        s = sgsub(s, '(%u)', function(a)
            return delimiter .. slower(a)
        end)

        if underlineFirst then
            s = ssub(s, 2)
        end
        s = _M.ltrim(s, delimiter)
    end

    return s
end

function _M.kebab(s)

    return _M.snake(s, '-')
end

function _M.allNum(s)

    return not sfind(s, '%D') and true or false
end

function _M.allAlpha(s)

    return not sfind(s, '%A') and true or false
end

function _M.allCtl(s)

    return not sfind(s, '%C') and true or false
end

function _M.allSpace(s)

    return not sfind(s, '%S') and true or false
end

function _M.allPunct(s)

    return not sfind(s, '%P') and true or false
end

function _M.allWord(s)

    return not sfind(s, '%W') and true or false
end

function _M.allUpper(s)

    return not sfind(s, '%U') and true or false
end

function _M.allLower(s)

    return not sfind(s, '%L') and true or false
end

function _M.hasNum(s)

    return sfind(s, '%d') and true or false
end

function _M.hasAlpha(s)

    return sfind(s, '%a') and true or false
end

function _M.hasWord(s)

    return sfind(s, '%w') and true or false
end

function _M.hasPunct(s)

    return sfind(s, '%p') and true or false
end

function _M.hasCtl(s)

    return sfind(s, '%c') and true or false
end

function _M.hasSpace(s)

    return sfind(s, '%s') and true or false
end

function _M.hasLower(s)

    return sfind(s, '%l') and true or false
end

function _M.hasUpper(s)

    return sfind(s, '%u') and true or false
end

function _M.neat(s, delim)

    local dd = delim .. delim
    while(sfind(s, dd)) do
        s = sgsub(s, dd , delim)
    end

    s = _M.trim(s, delim)

    return s
end

function _M.lregQuote(s)

    local t = lregQuoteCache[s]
    if t then
        return t
    end

    local ret = escape(s)
    lregQuoteCache[s] = ret

    return ret
end

_M.quote = _M.lregQuote

function _M.pregQuote(s, delimiter)

    local noDelim = true
    if not delimiter then
        local t = pregQuoteCache[s]
        if t then
            return t
        end
    else
        noDelim = false
    end

    delimiter = delimiter or '\\'
    local pat = [=[[{}=!<>|:%-%.%+%[%]%(%)%$%^%?%*]]=]
    local replace = delimiter .. '%1'
    local ret, times = sgsub(s, pat, replace)
    
    if noDelim then
        pregQuoteCache[s] = ret
    end

    return ret
end

function _M.plural(s)

    return deformation.pluralize(s)
end

function _M.singular(s)

    return deformation.singularize(s)
end

function _M.after(s, sign, plain)

    local ret

    local i, j = sfind(s, sign, nil, plain)
    if i then
        ret = ssub(s, i + 1)
    end

    return ret
end

function _M.before(s, sign, plain)

    local ret

    local i, j = sfind(s, sign, nil, plain)
    if i then
        ret = ssub(s, 1, i - 1)
    end

    return ret
end

function _M.substr(s, start, length)

    if length then
        if length > 0 then
            length = length + start - 1
        else
            length = length - 1
            if start < 0 then
                -- start = start - 1
            end
        end
    end

    return ssub(s, start, length)
end

function _M.rematch(subject, regex, options, ctx, res)

    if not options then
        options = 'jo'
    end

    if not ctx then
        return rematch(subject, regex, options)
    end
    if not res then
        return rematch(subject, regex, options, ctx)
    end
    
    return rematch(subject, regex, options, ctx, res)
end

function _M.regmatch(subject, regex, options)

    if not options then
        options = 'jo'
    end
    
    return regmatch(subject, regex, options)
end

function _M.refind(subject, regex, options, ctx, nth)

    if not options then
        options = 'jo'
    end

    if not ctx then
        return refind(subject, regex, options)
    end

    if not nth then
        return refind(subject, regex, options, ctx)
    end

    return refind(subject, regex, options, ctx, nth)
end

function _M.refindp(subject, regex, options)

    regex = _M.pregQuote(regex)

    return _M.refind(subject, regex, options)
end

function _M.refindpi(subject, regex, options)

    regex = _M.pregQuote(regex)
    
    if options then
        options = 'i' .. options
    else
        options = 'ijo'
    end

    return _M.refind(subject, regex, options)
end

function _M.resub(subject, regex, replace, options)

    if not options then
        options = 'jo'
    end

    return resub(subject, regex, replace, options)
end

function _M.regsub(subject, regex, replace, options)

    if not options then
        options = 'jo'
    end

    return regsub(subject, regex, replace, options)
end

function _M.regsubp(subject, regex, replace)

    regex = _M.pregQuote(regex)

    local options = 'jo'

    return regsub(subject, regex, replace, options)
end

function _M.regsubpi(subject, regex, replace)

    regex = _M.pregQuote(regex)

    local options = 'ijo'

    return regsub(subject, regex, replace, options)
end

function _M.rereplace(subject, regex, replace, options)

    if not options then
        options = 'jo'
    end
    local lookups = {}

    local vt, rtype = type(regex), type(replace)
    if vt == 'table' then
        if rtype == 'table' then
            for i, v in ipairs(regex) do
                lookups[v] = replace[i] or ''
            end
        elseif rtype == 'string' then
            for i, v in ipairs(regex) do
                lookups[v] = replace
            end
        end
    else
        lookups[regex] = replace or ''
    end

    for k, v in pairs(lookups) do
        subject = regsub(subject, k, v, options)
    end

    return subject
end

function _M.resplit(subject, regex, options)

    if not options then
        options = 'jo'
    end

    return resplit(subject, regex, options)
end

function _M.rematchAll(subject, regex, options)

    if not options then
        options = 'jo'
    end

    local it, err = regmatch(subject, regex, options)

    if not it then
        return 
    end
 
    local ret = {}

    while true do
        local m, err = it()
        if err then break end
        if not m then break end
        tapd(ret, m)
    end

    return ret
end

_M.pos = string.find
_M.strpos = _M.pos

function _M.parseCallback(callback, default)

    if _M.contains(callback, '@') then
        return unpack(_M.split(callback, '@', 2))
    else
        return callback, default
    end
end

function _M.substrCount(s, substr)

    local s, count = sgsub(s, substr, '')

    return count
end

_M.amount = _M.substrCount

function _M.fmtv(s)

    local vars = {}
    local varCount = 0
    local t
    for w in sgmatch(s, '{(%w+)}') do
        t = vars[w]
        if not t then
            vars[w] = w
            varCount = varCount + 1
        end
    end

    local index = 1
    local gotCount = 0
    while true do
        local varName, varValue = debug.getlocal(2, index)
        if not varName then break end
        if vars[varName] then
            vars[varName] = varValue
            gotCount = gotCount + 1
        end
        index = index + 1
        if gotCount >= varCount then
            break
        end
    end
    
    s = sgsub(s, '({(%w+)})', function(m, m1)
        return vars[m1]
    end)

    return s
end

function _M.findp(s, search, pos)

    return sfind(s, search, pos, true)
end

function _M.rfindAny()

end

function _M.rfind(s, search, pos, plain)

    local len = slen(s)
    s = sreverse(s)
    if plain then
        search = sreverse(search)
    end
    
    local i, j = sfind(s, search, pos, plain)
    if i then
        return len - j + 1, len - i + 1
    else
        return
    end
end

function _M.rfindp(s, search, pos)

    return _M.rfind(s, search, pos, true)
end

_M.rev = sreverse

function _M.words(value, words, theEnd)

    theEnd = theEnd or '...'
    words = words or 100
    local matches = _M.rematch(value, '^\\s*+(?:\\S++\\s*+){1,' .. words .. '}')
    
    if not matches or slen(value) == slen(matches[0]) then
        
        return value
    end
    
    return _M.rtrim(matches[0]) .. theEnd
end

function _M.rpos(s, f)   

    if s and f then
        local t = true
        local offset = 1
        local result = nil
        while (t)
        do
            local tmp = sfind(s, f, offset) 
            if tmp then
                offset = offset + 1
                result = tmp
            else
                t = false
            end
        end
        return result
    else
        return nil
    end   
end  

function _M.stripTags(s)

    return _M.rereplace(s, [[<[^>]*>]], '')
end

-- rounds a number to the nearest decimal places
local function roundNum(val, decimal)

    if decimal then
        return mfloor((val * 10 ^ decimal) + 0.5) / (10 ^ decimal)
    else
        return mfloor(val + 0.5)
    end
end

function _M.formatNumber(s, decimals, dec_point, thousands_sep)

    local amount = s
    decimals = decimals or 0
    dec_point = dec_point or '.'
    thousands_sep = thousands_sep or ','

    local str_amount, formatted, famount, remain

    famount = mabs(roundNum(amount, decimals))
    famount = mfloor(famount)

    remain = roundNum(mabs(amount) - famount, decimals)

    -- comma to separate the thousands
    formatted = famount
    local sepPat = '%1' .. thousands_sep .. '%2'
    local k
    while true do
        formatted, k = sgsub(formatted, "^(-?%d+)(%d%d%d)", sepPat)
        if k == 0 then
            break
        end
    end

    -- attach the decimal portion
    if decimals > 0 then
        remain = ssub(tostring(remain), 3)
        formatted = formatted .. dec_point .. remain ..
            srep("0", decimals - slen(remain))
    end

    return formatted
end

function _M.pad(s, length, padStr, padStyle)

    length = length or 0
    padStr = padStr or ' '
    padStyle = padStyle or 0
    local scount = slen(s)
    local padCount = length - scount
    if padCount <= 0 then
        return s
    end

    local padStrLen = slen(padStr)

    local padStrs

    if padStyle == 0 or padStyle == 1 then
        if padStrLen == 1 then
            padStrs = srep(padStr, padCount)
        else
            padStrs = srep(padStr, padCount / padStrLen) .. ssub(padStr, 1, padCount % padStrLen)
        end
        if padStyle == 0 then
            s = s .. padStrs
        else
            s = padStrs .. s
        end
    elseif padStyle == 2 then
        local padRightCount = mceil(padCount / 2)
        local padLeftCount = padCount - padRightCount

        if padStrLen == 1 then
            s = srep(padStr, padLeftCount) .. s .. srep(padStr, padRightCount)
        else
            local padRight = srep(padStr, padRightCount / padStrLen) .. ssub(padStr, 1, padRightCount % padStrLen)
            local padLeft = srep(padStr, padLeftCount / padStrLen) .. ssub(padStr, 1, padLeftCount % padStrLen)
            s = padLeft .. s .. padRight
        end
    else
        error('invalid pad style')
    end

    return s
end

function _M.make(subList, pattern, style)

    style = style or 1
    local ret = {}

    local patType = type(pattern)

    if patType == 'string' then
        for _, v in ipairs(subList) do
            if style == 1 then
                v = _M.format(pattern, v)
            elseif style == 2 then
                v = pattern .. v
            elseif style == 3 then
                v = v .. pattern
            end

            tapd(ret, v)
        end
    elseif patType == 'function' then
        for _, v in ipairs(subList) do
            v = pattern(v)
            tapd(ret, v)
        end
    end

    return unpack(ret)
end

function _M.str(s, needle, beforeNeedle)

    local i, j = sfind(s, needle)
    if not i then
        return false
    end

    local ret
    if beforeNeedle then
        ret = ssub(s, 1, i - 1)
    else
        ret = ssub(s, i)
    end

    return ret
end


function _M.findTagEnd(s, tagBegin, tagEnd, lastPos)

    local tagOpenedNum, tagClosedNum = 0, 0
    local loopLimit, loopCount = 1000, 0
    local strLength = slen(s)
    local i, j, ib, jb, ie, je

    if not tagEnd then
        tagEnd = "</" ..tagBegin .. ">"
        tagBegin = "<" .. tagBegin
    end

    if lastPos then
        tagOpenedNum = 1
    else
        lastPos = 1
    end

    while true do
        if (loopCount == loopLimit) or (lastPos >= strLength) then
            return 
        end

        ib, jb = sfind(s, tagBegin, lastPos)
        ie, je = sfind(s, tagEnd, lastPos)

        if ib then
            if ie then
                if ib < ie then
                    lastPos = jb + 1
                    tagOpenedNum = tagOpenedNum + 1
                    i, j = sfind(s, tagBegin, lastPos)
                    if i and j < ie then
                        lastPos = j + 1
                        tagOpenedNum = tagOpenedNum + 1
                    end
                else
                    lastPos = je + 1
                    tagClosedNum = tagClosedNum + 1
                    if tagOpenedNum == tagClosedNum then
                        return je
                    end
                end
            else
                lastPos = jb + 1
                tagOpenedNum = tagOpenedNum + 1
            end
        else
            if ie then
                lastPos = je + 1
                tagClosedNum = tagClosedNum + 1
                if tagOpenedNum == tagClosedNum then
                    return je
                end
            else
                return
            end
        end
 
        loopCount = loopCount + 1
    end

    return lastPos
end

return _M

