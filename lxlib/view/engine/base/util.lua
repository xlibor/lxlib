
local _M = {
  _cls_ = ''
}

local sub, gsub = string.sub, string.gsub

local lx = require('lxlib')
local app, lf, tb, str = lx.kit()
local null = ngx.null

function _M.escape(s, c)
    
    local transed
    s, transed = _M.toStr(s)

    if transed then
        return s
    end
    
    if s then
        s = lf.htmlentities(s, c)
    end

    return s
end

function _M.toStr(s)

    if s == nil or s == null then return '' end

    local vt = type(s)
    local transed
    if vt == 'function' then
        return _M.toStr(s())
    elseif vt == 'table' then
        local cls = s.__cls
        if cls then
            if s.toStr then
                s = s:toStr()
                transed = true
            end
        end
    end

    return tostring(s), transed
end

return _M

