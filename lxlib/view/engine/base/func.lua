
local _M = {
    _cls_ = ''
}
local mt = { __index = _M }

local lx = require('lxlib')
local app = lx.app()

local util = require('lxlib.view.engine.base.util')

function _M.escape(s, c)

    return util.escape(s, c)
end

function _M.toStr(s)

    return util.toStr(s)
end

function _M.range(low, high, step)

    local tbl = {}
    local rangeLow, rangeHigh, step = low, high, step
    local rangeType = type(rangeLow)
    
    if rangeType == 'number' then
        if step then
            for i = rangeLow, rangeHigh, step do tapd(tbl,i) end
        else
            for i = rangeLow, rangeHigh do tapd(tbl,i) end
        end
    elseif rangeType == 'string' then
        
    end

    return tbl
end

function _M.loopIter(t, loop, loopArgs) 
 
    local a = {}  
    local loopControl = false
    
    if type(t) ~= 'table' then
        error('loop targe must be table')
    end

    local cls = t.__cls
    if cls then

        return _M.myPairs(t)    
    end

    if loopArgs then
        loopControl = true
        local rangeLow, rangeHigh, step = loopArgs.low, loopArgs.high, loopArgs.step
        if rangeLow then
            if step then
                for i = rangeLow, rangeHigh, step do tapd(t,i) end
            else
                for i = rangeLow, rangeHigh do tapd(t,i) end
            end
        end
    end
 
    local offset, maxLength

    if loopControl then
        offset, maxLength = loopArgs.offset, loopArgs.length
    end

    if #t > 0 then
        if not offset then
            for i, n in ipairs(t) do a[#a+1] = i end

        else
            if not maxLength then
                for i = offset, #t do a[#a+1] = i end
            else
                for i = offset, maxLength do a[#a+1] = i end
            end
        end
    else
        if not offset then
            for n in pairs(t) do a[#a+1] = n end
        else
            if not maxLength then
                for n in pairs(t) do
                    i = i + 1
                    if i >= offset then a[#a+1] = n end
                end
            else
                for n in pairs(t) do
                    i = i + 1
                    if i >= offset and i <= maxLength then a[#a+1] = n end
                end
            end
        end
    end

      local length = #a
    local i = 0
    local k,v 
 
    return function()  
        i = i + 1  
        k = a[i]; v = t[k]
        loop.index = i; loop.key = k; loop.value = v
        loop.iteration = i 
        loop.remaining = length - i
        loop.index0 = i - 1
        loop.length = length; loop.count = length
        loop.first = (i == 1)
        loop.last = (i == length)
        
        return k, v
    end  
end

function _M.myPairs(var)

    local cls = var.__cls

    if cls then
        if var:__is('eachable') then
            return var:toEach()
        else
            error('can not loop ' .. cls)
        end
    else
        return pairs(var)
    end
end

return _M

