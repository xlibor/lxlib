
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str, new = lx.kit()

local ssub, sgsub, slen = string.sub, string.gsub, string.len
local quotes

function _M._init_()

    quotes = {}
    local s = '-.+[]()$^%?*'

    for i = 1, slen(s) do
        quotes[ssub(s, i, i)] = true
    end

end

function _M:new()

    local this = {
    }
    
    oo(this, mt)

    return this
end

function _M:compile(route)

    local hostVars, pathVars = {}, {}
    local vars = {}
    local hostRegex
    local hostTokens = {}
    local host = route:getHost()

    local path, result, pathPre
    local tokens, regex
    
    if host ~= '' then
        result = self:compilePattern(route, host, true)

        hostVars = result.vars
        vars = hostVars

        hostTokens = result.tokens
        hostRegex = result.regex
    end

    path = route:getPath()
    result = self:compilePattern(route, path, false)

    pathPre = result.pathPre

    pathVars = result.vars
    tb.listAdds(vars, pathVars)
    tb.unique(vars)
 
    tokens = result.tokens
    regex = result.regex

    return new('compiledRoute',
        pathPre,
        regex,
        tokens,
        pathVars,
        hostRegex,
        hostTokens,
        hostVars,
        vars
    )
end

function _M:preparePattern(pattern)

    local ret = {}
    local inToken
    local s
 
    for i = 1, slen(pattern) do
        s = ssub(pattern, i, i)
        if s == '{' then
            inToken = true
        elseif s == '}' then
            inToken = false
        end

        if not inToken then
            if quotes[s] then
                s = '%' .. s
            end
        end
        tapd(ret, s)
    end

    return table.concat(ret)
end

function _M:compilePattern(route, pattern, isHost)

    local tokens, vars, matches = {}, {}, {}
    local separator = isHost and '%.' or '/'
    local search = '(' .. separator .. "?)%{([%w_-]+)(%??)%}"
    
    pattern = self:preparePattern(pattern)

    local regex = sgsub(pattern, search, function(delim, m, optionalSign)

        tapd(vars, m)
        local pat
        local defedPat = route:getRequirement(m)

        if defedPat then
            -- defedPat = '[' .. defedPat .. ']'
        end
        pat = defedPat or "[^" .. separator .. "]"
        optionalSign = optionalSign or ''
        if slen(optionalSign) > 0 then 
            optionalSign = true
        else
            optionalSign = nil
        end

        if not optionalSign then
            if defedPat then
                pat = '(' .. pat .. ')'
            else
                pat = '(' .. pat .. '+)'
            end
        else
            pat = '?(' .. pat .. '*)'
        end
 
        return delim .. pat
    end)
    
    local first = ssub(regex, 1, 1)
    local last  = ssub(regex, -1, 1)

    if not isHost then
        if first ~= '/' then
            regex = '/' .. regex
        end

        if last ~= '/' then
            regex = regex .. '/'
        end
    end

    regex = "^" .. regex .. "???$"

    local result = {
        regex = regex,
        vars = vars
    }

    return result
end

return _M

