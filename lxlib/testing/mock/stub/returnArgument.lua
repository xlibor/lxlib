
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'unit.mock.stub.return'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        argumentIndex = nil
    }
    
    return oo(this, mt)
end

function _M:ctor(argumentIndex)

    self.argumentIndex = argumentIndex
end

function _M:invoke(invocation)

    if invocation.parameters[self.argumentIndex] then
        
        return invocation.parameters[self.argumentIndex]
    else 
        
        return
    end
end

function _M:toStr()

    return fmt('return argument #%d', self.argumentIndex)
end

return _M

