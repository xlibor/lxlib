
local lx, _M, mt = oo{
    _cls_ = '',
    _bond_ = 'unit.mock.stub'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
    }
    
    return oo(this, mt)
end

function _M:ctor(valueMap)

    self.valueMap = valueMap
end

function _M:invoke(invocation)

    local ret
    local parameterCount = #invocation.parameters

    for _, map in ipairs(self.valueMap) do
        if lf.isTbl(map) and parameterCount == #map - 1 then
            ret = tb.pop(map)
            if tb.eq(invocation.parameters, map) then
                
                return ret
            end
        end
    end
    
    return
end

function _M:toStr()

    return 'return value from a map'
end

return _M

