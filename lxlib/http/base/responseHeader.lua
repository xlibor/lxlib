
local _M = { 
    _cls_ = '',
    _ext_ = 'col',
}

local mt = { __index = _M }

local lx = require('lxlib')
local app, lf, tb, str = lx.kit()

function _M:ctor(data)
    
    self:useDict(data)

    local col = lx.col()
    col:dotable{get = true, set = true, sign = '|'}
    self.cookies = col
end

function _M:setCookie(ck)
    
    local cookies = self.cookies
    local name, domain, path = ck.name, ck.domain or '', ck.path
 
    cookies:set(domain..'|'..path..'|'..name, ck)

end

function _M:getCookies(style)

    style = style or 1

    if style == 1 then
        return self.cookies:flatten(2)
    elseif style == 2 then
        return self.cookies:all()
    else
        error('unsupported style')
    end
end

return _M

