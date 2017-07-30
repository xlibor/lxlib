
local lx, _M, mt = oo{
    _cls_ = '',
    _bond_ = 'unit.mock.stub'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        stack = nil,
        value = nil
    }
    
    return oo(this, mt)
end

function _M:ctor(stack)

    self.stack = stack
end

function _M:invoke(invocation)

    self.value = tb.shift(self.stack)
    if self.value:__is('unit.mock.stub') then
        self.value = self.value:invoke(invocation)
    end
    
    return self.value
end

function _M:toStr()

    local exporter = new('unit.exporter')
    
    return fmt('return user-specified value %s', exporter:export(self.value))
end

return _M

