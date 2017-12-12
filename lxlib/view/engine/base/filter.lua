
local _M = {
    _cls_ = ''
}
local mt = { __index = _M }

local lx = require('lxlib')
local util = require('lxlib.view.engine.base.util')
local lf = lx.f
local sub, gsub = string.sub, string.gsub

function _M:new()

    local this = {
        method = '',
        args = {},
        otherArg = nil,
        target = nil
    }
    
    setmetatable(this, mt)

    return this
end

function _M.escape(s, c)

    return util.escape(s, c)
end

function _M._escape(s, c)

    return util.escape(s, c)
end

function _M.toStr(s)

    return util.toStr(s)
end

function _M._join(target, args)

    local delim = args[1]
    local ret = lx.str.join(target, delim)
 
    return ret 
end

function _M._length(target)

    local tbl = target
    local ret = 0
    if type(tbl) == 'table' then
        if #tbl > 0 then 
            ret = #tbl
        elseif next(tbl) then
            local count = 0
            for k in pairs(tbl) do
                count = count + 1
            end
            ret = count
        end
    else
        ret = 0
    end
 
    return ret 
end

function _M._slice(target, args)

    local start, length = args[1], args[2]
    local tType = type(target)
    local tbl = {}

    if tType == 'table' then
        if #target > 0 then
            for i = start, start+length - 1 do 
                tapd(tbl, target[i])
            end
        elseif next(target) then
            local i = 0
            for k, v in ipairs(target) do
                i = i + 1
                if i >= start and i <= start + length - 1 then
                    tbl[k] = v
                end
            end
        else

        end
    elseif tType == 'string' then

    end

    return tbl
end

function _M._first(target)

    local var = target
    if type(var) == 'table' then
        return var[1]
    elseif type(var) == 'string' then
        return string.sub(var, 1, 1)
    end
end

function _M._last(target)

    local var = target
    if type(var) == 'table' then
        return var[#var]
    elseif type(var) == 'string' then
        return string.sub(var, -1, -1)
    end
end

function _M._upper(target)

    local str = target
    if type(str) == 'string' then
        str = string.upper(str)
    else
        str = tostring(str)
        str = string.upper(str)
    end

    return str
end

function _M._lower(target)

    local str = target
    if type(str) == 'string' then
        str = string.lower(str)
    else
        str = tostring(str)
        str = string.lower(str)
    end

    return str
end

function _M._abs(target)

    local num = target
    if type(num) == 'number' then
        num = math.abs(num)
    else
        num = tonumber(num)
        if num then
            num = math.abs(num)
        else
            error('can not tonumber')
        end
    end

    return num
end

function _M._valid(target)

    return not lf.isEmpty(target)
end

function _M._operator_in(target, tbl)

    local ret = false
    if type(tbl) == 'table' then
        if #tbl > 0 then
            for k, v in ipairs(tbl) do
                if target == v then
                    ret = true
                    break;
                end
            end
        elseif next(tbl) then
            for k, v in pairs(tbl) do
                if target == v then
                    ret = true
                    break;
                end
            end
        end
    else

    end

    return ret
end

function _M:test(method, ...)

    self.method = method
    self.args = {...}

    return self
end

function _M:doTest(target)

    local method = self.method
    local args = self.args
    local ret
    local f = self['_'..method] 
    if f then
        local otherArg = self.otherArg
        if otherArg then
            ret = f(target, otherArg)
            self.otherArg = nil
            return ret
        else
            return f(target, args)
        end
    else
        error(self.__cls ..' not support ' .. method)
    end
 
end

function _M:addOtherArg(p)

    self.otherArg = p

    return self
end

local function mtMul(p1, p2)

    return p2:doTest(p1)
end

local function mtAdd(p1, p2)
 
end

local function mtSub(p1, p2)
 
end

local function mtDiv(p1, p2)
 
end

local function mtPow(p1, p2)

    return p1:addOtherArg(p2)
end

mt.__mul = mtMul
mt.__add = mtAdd
mt.__div = mtDiv
mt.__sub = mtSub
mt.__pow = mtPow

return _M

