
local lx, _M, mt = oo{
    _cls_ = '',
    _bond_ = 'unit.mock.stub'
}

local app, lf, tb, str = lx.kit()

function _M:invoke(invocation)

    if not invocation:__is('unit.mock.invocation.object') then
        lx.throw('unit.mock.exception', 
            'The current object can only be returned when mocking an ' .. 
            'object, not a static class.'
        )
    end
    
    return invocation.object
end

function _M:toStr()

    return 'return the current object'
end

return _M

