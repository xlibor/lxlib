
local lx, _M = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

function _M:redirectPath()

    if self:__has('redirectTo') then
        
        return self:redirectTo()
    end
    
    return self.redirectTo or '/home'
end

return _M

