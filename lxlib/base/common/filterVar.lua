
local _M = {
    _cls_ = ''
}

local slen = string.len
local rematch = ngx.re.match

local _filterEmailPattern = [[^(?:[\w\!\#\$\%\&\'\*\+\-\/\=\?\^\`\{\|\}\~]+\.)*[\w\!\#\$\%\&\'\*\+\-\/\=\?\^\`\{\|\}\~]+@(?:(?:(?:[a-zA-Z0-9_](?:[a-zA-Z0-9_\-](?!\.)){0,61}[a-zA-Z0-9_-]?\.)+[a-zA-Z0-9_](?:[a-zA-Z0-9_\-](?!$)){0,61}[a-zA-Z0-9_]?)|(?:\[(?:(?:[01]?\d{1,2}|2[0-4]\d|25[0-5])\.){3}(?:[01]?\d{1,2}|2[0-4]\d|25[0-5])\]))$]]
local _filterIntBase10Pattern = [[^-?[1-9][0-9]*$]]
local _filterFloatRegex = [[^-?\d*?\.?\d*?$]]
local _filterIpv4Pattern = [[^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$]]
local _filterIpv6Pattern = [[^(((?=(?>.*?(::))(?!.+\3)))\3?|([\dA-F]{1,4}(\3|:(?!$)|$)|\2))(?4){5}((?4){2}|(25[0-5]|(2[0-4]|1\d|[1-9])?\d)(\.(?7)){3})\z]]
local _urlPattern = [[(?:(\w+)://)?(?:(\w+)\:(\w+)@)?([^/:]+)?(?:\:(\d*))?([^#?]+)?(?:\?([^#]+))?(?:#(.+$))?]]
local _urlFields = {'url','scheme','user','pass',
        'host','port','path','query','fragment'
}

function _M.filter(var, filter, options)

    local ret = false

    if filter then
        if type(var) ~= 'string' or slen(var) == 0 then
            return ret
        end
    end

    if filter == 'email' then
        ret = rematch(var, _filterEmailPattern, 'ijo')
        if ret then ret = ret[0] end
    elseif filter == 'int' then
        ret = rematch(var, _filterIntBase10Pattern, 'ijo')
        if ret then ret = ret[0] end
    elseif filter == 'float' then
        ret = rematch(var, _filterFloatRegex, 'ijo')
        if ret then ret = ret[0] end
    elseif filter == 'ip' then
        ret = rematch(var, _filterIpv4Pattern, 'ijo')
        if ret then ret = ret[0] end
    elseif filter == 'url' then
        ret = rematch(var, _urlPattern, 'ijo')
        if ret then ret = ret[0] end
    elseif filter == 'boolean' then
        if var == '1' or var == 'true' or var == 'on' or var == 'yes' then
            ret = true
        end
    end

    ret = ret or false

    return ret
end

function _M.parseUrl(url, option)

    local m = rematch(url, _urlPattern, 'ijo')
    local ret = {}

    for i, v in ipairs(_urlFields) do
        ret[v] = m[i - 1]
    end

    if option then
        if option == 'port' then
            ret = tonumber(ret.port)
        else
            ret = ret[option]
        end
    end

    return ret
end

return _M

