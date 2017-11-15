
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'text'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        passwordDefaults = {setter = true}
    }
    
    return oo(this, mt)
end

-- The specific defaults for the image class.
-- @var table
-- Gets all default values.
-- @return table

function _M:getDefaults()

    local defaults = parent.getDefaults()
    
    return tb.merge(defaults, self.passwordDefaults)
end

return _M

