
local _M = {
    _cls_ = ''
}

local mt = {__index = _M}

local lx = require('lxlib')
local app, lf, tb, str = lx.kit()
local throw = lx.throw

local fs = lx.fs

local sfind, slen, ssub, sgmatch = string.find, string.len, string.sub, string.gmatch

function _M:new(bag, methods)

    local this = {
        bag = bag, 
        bagName = bag.__cls,
        methods = methods
    }

    setmetatable(this, mt)

    return this
end

function _M:check()

    local bag, bagName, methods = self.bag, self.bagName, self.methods
    local t

    for funcName, v in pairs(methods) do
        local params, subItem, isStatic = v.params, v.subItem, v.isStatic
        local returns = v.returns
        local items = v.items

        local parent, func, newFunc
        if subItem then
            parent = bag[subItem]
            func = parent[funcName]
        else
            parent = bag
            func = bag[funcName]
        end

        newFunc = function(...)
            local obj
            local args, len = lf.copyArgs(...)
            if not isStatic then
                obj = tb.delete(args, 1)
                if not lf.isObj(obj) then
                    throw('badMethodCallException', 
                        'may not use obj:' .. funcName
                    )
                end
            end

            self:doCheck(funcName, params, args, 1)

            if funcName == 'ctor' and items then
                func(...)
                local props = {}
                args = {}
                local i = 1
                for k, item in pairs(items) do
                    t = rawget(obj, k)
                    args[i] = t
                    tapd(props, {item, k})
                    i = i + 1
                end
                self:doCheck('ctor', props, args, 3)
            else
                if returns then

                    local rets = {func(...)}
                    self:doCheck(funcName, returns, rets, 2)

                    return unpack(rets)
                else
                    return func(...)
                end
            end
        end

        parent[funcName] = newFunc
    end

end

function _M:doCheck(funcName, params, args, checkStyle)

    for index, p in ipairs(params) do
        local paramType, paramName = p[1], p[2]
        local arg = args[index]
        local argType = type(arg)
        local ptt = type(paramType)
        local validType
        local checked = false
        local err

        if ptt == 'table' then
            for _, validType in ipairs(paramType) do
                checked, err = self:checkType(validType, arg, argType)
                if checked then break end
            end

            if not checked then
                validType = str.join(paramType, ' or ')

                self:formatThrow(checkStyle, funcName, index, paramName, validType, arg, err)
            end
        else
            validType = paramType
            checked, err = self:checkType(validType, arg, argType)
        end

        if not checked then
            self:formatThrow(checkStyle, funcName, index, paramName, validType, arg, err)
        end
    end

end

function _M:checkType(validType, arg, argType)

    local t

    if validType == 'string' or validType == 'number'
        or validType == 'boolean' or validType == 'table'
        or validType == 'function' then

        if argType ~= validType then

            return false
        end
    elseif validType == 'object' then
        if argType ~= 'table' then

            return false
        elseif not arg.__cls then

            return false
        end
    elseif validType == 'integer' then

        return lf.isInt(arg)
    elseif validType == 'float' then

        return argType == 'number' or lf.isFloat(arg)  
    elseif validType == 'mixed' then
        if argType == 'nil' then

            return false
        end
    elseif validType == 'nil' then
        if argType ~= 'nil' then
            return false
        end
    elseif validType == 'self' then
        
        return lf.isA(arg, self.bagName)
    else
        if ssub(validType, -1) == ']' then
            validType = ssub(validType, 1, -3)
            if argType ~= 'table' then return false end
            if #arg == 0 then
                return false, '(empty table)'
            end
            local invaidIndex = 1
            local allValid = true
            local err
            for i, each in ipairs(arg) do
                invaidIndex = i
                if lf.isObj(each) then
                    if not lf.isA(each, validType) then
                        allValid = false
                        err = i .. ' is not ' .. validType
                        break
                    end
                else
                    allValid = false
                    err = i .. ' is not obj'
                    break
                end
            end
            if not allValid then
                return false, '(item ' .. err .. ')'
            end
        else
            if lf.isObj(arg) then
                return lf.isA(arg, validType)
            else
                return false
            end
        end
    end

    return true
end

function _M:formatThrow(checkStyle, funcName, index, paramName, validType, arg, err)

    local bagName = self.bagName

    local argType = type(arg)
    if argType == 'table' then
        if arg.__cls then
            argType = arg.__cls
        end
    end

    local checkContent
    if checkStyle == 1 then
        checkContent = 'params'
    elseif checkStyle == 2 then
        checkContent = 'results'
    elseif checkStyle == 3 then
        checkContent = 'items'
    end

    local info = 'in bag [' .. bagName .. '], function [' .. funcName ..
        '], <br>' .. checkContent .. '['.. index .. '] ' .. paramName ..
        ' must be [' .. validType .. '], got ' .. argType

    if err then
        info = info .. ' ' .. err
    end

    lx.throw('invalidArgumentException', info)

end

return _M

