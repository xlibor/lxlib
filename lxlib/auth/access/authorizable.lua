
local lx, _M = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

function _M:can(ability, arguments)

    arguments = arguments or {}
    
    return app.gate:forUser(self):check(ability, arguments)
end

function _M:cant(ability, arguments)

    arguments = arguments or {}
    
    return not self:can(ability, arguments)
end

function _M:cannot(ability, arguments)

    arguments = arguments or {}
    
    return self:cant(ability, arguments)
end

return _M

