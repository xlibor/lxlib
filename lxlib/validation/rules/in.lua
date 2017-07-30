
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

function _M:new(values)

    local this = {
        rule = 'in',
        values = values
    }
    
    return oo(this, mt)
end

function _M:toStr()

    return self.rule .. ':' .. str.join(self.values, ',')
end

return _M

