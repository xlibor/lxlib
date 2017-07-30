
local _M = {
    _cls_ = ''
}

local mt = {__index = _M}

local lx = require('lxlib')
local app, lf, tb, str = lx.kit()
local fs = lx.fs

local fmtTypes = {
    str = 'string',
    int = 'integer',
    num = 'number',
    bool = 'boolean',
    obj = 'object',
    null = 'nil',
    func = 'function',
}

local sfind, slen, sgmatch = string.find, string.len, string.gmatch
local regmatch = str.regmatch
local rematch = str.rematch

function _M.getAnnotations(filePath)

    local methods
    local sc = fs.get(filePath)
    local pat = [[(-- @(param|return|item)([\s\S]*?))function _M(.*?)(\w+)\(]]

    local it, err = regmatch(sc, pat)
    if not it then return end
    local code

    while true do
        local m, err = it()
        if err then
            break 
        end
        if not m then break end

        code = m[1]
        if not methods then
            methods = {}
        end
        local lines = str.split(code, '\n')
        local t, extra, subItem, isStatic
        local params = {}
        local items
        local returns
        local methodName, paramType, paramDef, paramName

        extra = m[4]
        methodName = m[5]

        if slen(extra) > 0 then
            isStatic = str.sub(extra, -1) == '.'
            subItem = str.trim(extra, '[%.:]')
            if slen(subItem) == 0 then
                subItem = false
            end
        end

        for _, line in ipairs(lines) do
            m = rematch(line, [[-- @(param|return|item) (.*)]])
            if m then
                local tag = m[1]
                t = m[2]
                t = str.trim(t)
                if tag == 'param' or tag == 'item' then
                    t = str.gsub(t, '%s+', ' ')
                    paramDef = str.split(t, ' ')
                    paramType, paramName = paramDef[1], paramDef[2] or ''
                    if slen(paramName) == 0 then
                        error('invalid paramName in ' .. filePath ..
                            ' for method [' .. methodName .. ']')
                    end
                    if sfind(paramType, '|') then
                        paramType = str.split(paramType, '|')
                    end
                    paramType = _M.formatParamType(paramType)
                    paramDef[1] = paramType

                    if tag == 'item' then
                        if not items then items = {} end
                        items[paramName] = paramType
                    else
                        tapd(params, paramDef)
                    end
                elseif tag == 'return' then
                    t = str.gsub(t, '%s+', ' ')
                    if sfind(t, ' ') then
                        t = str.sub(t, 1, sfind(t, ' ') - 1)
                    end
                    
                    returns = {}
                    local returnDef = str.split(t, ',')
                    for _, ret in ipairs(returnDef) do
                        if sfind(ret, '|') then
                            ret = str.split(ret, '|')
                        end
                        ret = _M.formatParamType(ret)
                        ret = {ret, ''}
                        tapd(returns, ret)
                    end 
                end
            end
        end

        methods[methodName] = {
            params = params, subItem = subItem,
            isStatic = isStatic, returns = returns,
            items = items
        }
    end

    return methods
end

function _M.formatParamType(paramType)

    local t
    local vt = type(paramType)
    if vt == 'string' then
        t = fmtTypes[paramType]
        if t then
            paramType = t
        end

        return paramType
    elseif vt == 'table' then
        for i, v in ipairs(paramType) do
            t = fmtTypes[v]
            if t then
                paramType[i] = t
            end
        end

        return paramType
    else
        error('invalid paramType')
    end

end

return _M

