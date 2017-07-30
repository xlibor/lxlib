
local lx, _M, mt = oo{
    _cls_ = '',
    _bond_ = 'unit.mock.stub'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        exception = nil
    }
    
    return oo(this, mt)
end

function _M:ctor(exception)

    self.exception = exception
end

function _M:invoke(invocation)

    lx.throw(self.exception)
end

function _M:toStr()

    local exporter = new('unit.exporter')
    
    return fmt('raise user-specified exception %s', exporter:export(self.exception))
end

return _M

