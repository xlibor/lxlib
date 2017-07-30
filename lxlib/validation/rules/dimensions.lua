
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

function _M:new(constraints)

    local this = {
        constraints = constraints or {}
    }
    
    return oo(this, mt)
end

function _M:width(value)

    self.constraints['width'] = value
    
    return self
end

function _M:height(value)

    self.constraints['height'] = value
    
    return self
end

function _M:minWidth(value)

    self.constraints['min_width'] = value
    
    return self
end

function _M:minHeight(value)

    self.constraints['min_height'] = value
    
    return self
end

function _M:maxWidth(value)

    self.constraints['max_width'] = value
    
    return self
end

function _M:maxHeight(value)

    self.constraints['max_height'] = value
    
    return self
end

function _M:ratio(value)

    self.constraints['ratio'] = value
    
    return self
end

function _M:toStr()

    local result = ''
    for key, value in pairs(self.constraints) do
        result = result .. key .. '=' .. value .. ','
    end
    
    return 'dimensions:' .. str.substr(result, 1, -1)
end

return _M

