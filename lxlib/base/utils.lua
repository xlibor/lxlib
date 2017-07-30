
local _M = {
    _cls_ = ''
}

local restyRandom = require "resty.random"
local restyStr = require('resty.string')
local ssub, sgsub, sfind, slower = string.sub, string.gsub, string.find, string.lower
local sfmt, supper, sbyte, slen = string.format, string.upper, string.byte, string.len
local schar = string.char

local HTML_ENTITIES = {
    ["&"] = "&amp;",
    ["<"] = "&lt;",
    [">"] = "&gt;",
    ['"'] = "&quot;",
    ["'"] = "&#39;",
    -- ["/"] = "&#47;"
}

local CODE_ENTITIES = {
    ["{"] = "&#123;",
    ["}"] = "&#125;",
    ["&"] = "&amp;",
    ["<"] = "&lt;",
    [">"] = "&gt;",
    ['"'] = "&quot;",
    ["'"] = "&#39;",
    -- ["/"] = "&#47;"
}

function _M.htmlentities(s, c)

    if type(s) == "string" then
        if c then
            s = sgsub(s, "[}{\">/<'&]", CODE_ENTITIES)
        else
            s = sgsub(s, "[\">/<'&]", HTML_ENTITIES)
        end
    end

    return s
end

function _M.needArgs(...)

    local args = {...}
    local argsLen = #args
    local p1 = args[1]
    local p1Type = type(p1)

    if p1Type == 'table' then
        return p1, 1
    else
        return args, argsLen
    end
end

function _M.isWin()
    
    return package.config:sub(1,1) == '\\'
end

function _M.toHex(s, needUpper, spacer)

    local ret

    if not spacer then
        ret = restyStr.to_hex(s)
        if needUpper then
            ret = supper(ret)
        end
    else
        local sign = needUpper and 'X' or 'x'
        ret = (sgsub(s, "(.)", function(c)
            return sfmt("%02" .. sign .. "%s", sbyte(c), spacer or "")
        end))
    end

    return ret
end

function _M.atoi(s)

    return restyStr.atoi(s)
end

function _M.bytes(len)

    return restyRandom.bytes(len)
end

function _M.fromHex(s)

    return s:gsub('..', function(cc)
        return schar(tonumber(cc, 16))
    end)
end

function _M.fuseValue(item, dv)

    local itemType = type(item)
    if itemType == 'nil' then
        if type(dv) == 'function' then
            dv = dv()
        end
        item = dv
    else
        if dv then
            local dvType = type(dv)
            if dvType ~= itemType then
                if dvType == 'number' then
                    item = tonumber(item)
                    if not item then
                        item = dv
                    end
                elseif dvType == 'string' then
                    item = tostring(item)
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

function _M.needList(var)

    local vt = type(var)
    if vt == 'table' then
        if #var > 0 then
            return var
        elseif next(var) then
            return {var}
        else
            return {}
        end
    else
        return {var}
    end
end

function _M.getRange(len, offset, length)
    
    local last = len
    offset = offset or 1

    local t
 
    if offset < 0 then
        offset = len + offset + 1
    end

    if not length then
        last = len
    else
        if length > 0 then
            last = offset + length - 1
        else
            last = len + length
        end
    end

    if offset <= 0 then offset = 1 end
    if last <= 0 then last = 1 end

    return offset, last
end

return _M

