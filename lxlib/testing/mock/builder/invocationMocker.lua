
local lx, _M, mt = oo{
    _cls_ = '',
    _bond_ = 'unit.mock.builder.methodNameMatch'
}

local app, lf, tb, str, new = lx.kit()

function _M:new()

    local this = {
        collection = nil,
        matcher = nil,
        configurableMethods = {}
    }
    
    return oo(this, mt)
end

-- @param unit.mock.stub.matcherCollection  collection
-- @param unit.mock.matcher.invocation      invocationMatcher
-- @param table  configurableMethods

function _M:ctor(collection, invocationMatcher, configurableMethods)

    self.collection = collection
    self.matcher = new('unit.mock.matcher', invocationMatcher)
    self.collection:addMatcher(self.matcher)
    self.configurableMethods = configurableMethods
end

-- @return unit.mock.matcher

function _M:getMatcher()

    return self.matcher
end

-- @param mixed id
-- @return unit.mock.builder.invocationMocker

function _M:id(id)

    self.collection:registerId(id, self)
    
    return self
end

-- @param unit.mock.stub stub
-- @return unit.mock.builder.invocationMocker

function _M:will(stub)

    self.matcher.stub = stub
    
    return self
end

-- @param mixed value
-- @return unit.mock.builder.invocationMocker

function _M:willReturn(value, ...)

    local nextValues = {...}
    local stub
    if #nextValues == 0 then
        stub = new('unit.mock.stub.return', value)
    else
        stub = new('unit.mock.stub.consecutiveCalls', tb.merge({value}, nextValues))
    end

    return self:will(stub)
end

-- @param mixed reference
-- @return unit.mock.builder.invocationMocker

function _M:willReturnReference(reference)

    local stub = new('unit.mock.stub.returnReference', reference)
    
    return self:will(stub)
end

-- @param table valueMap
-- @return unit.mock.builder.invocationMocker

function _M:willReturnMap(valueMap)

    local stub = new('unit.mock.stub.returnValueMap', valueMap)
    
    return self:will(stub)
end

-- @param mixed argumentIndex
-- @return unit.mock.builder.invocationMocker

function _M:willReturnArgument(argumentIndex)

    local stub = new('unit.mock.stub.returnArgument', argumentIndex)
    
    return self:will(stub)
end

-- @param func callback
-- @return unit.mock.builder.invocationMocker

function _M:willReturnCallback(callback)

    local stub = new('unit.mock.stub.returnCallback', callback)
    
    return self:will(stub)
end

-- @return unit.mock.builder.invocationMocker

function _M:willReturnSelf()

    local stub = new('unit.mock.stub.returnSelf')
    
    return self:will(stub)
end

-- @return unit.mock.builder.invocationMocker

function _M:willReturnOnConsecutiveCalls(...)

    local stub = new('unit.mock.stub.consecutiveCalls', ...)
    
    return self:will(stub)
end

-- @param Exception exception
-- @return unit.mock.builder.invocationMocker

function _M:willThrowException(exception)

    local stub = new('unit.mock.stub.exception', exception)
    
    return self:will(stub)
end

-- @param mixed id
-- @return unit.mock.builder.invocationMocker

function _M:after(id)

    self.matcher.afterMatchBuilderId = id
    
    return self
end

-- Validate that a parameters matcher can be defined, throw exceptions otherwise.
-- @throws unit.mock.exception

function _M.__:canDefineParameters()

    if not self.matcher.methodNameMatcher then
        lx.throw('unit.mock.exception', 'Method name matcher is not defined, cannot define parameter ' .. 'matcher without one')
    end
    if self.matcher.parametersMatcher then
        lx.throw('unit.mock.exception', 'Parameter matcher is already defined, cannot redefine')
    end
end

function _M:getCurrMethodName()

    return self.matcher.methodNameMatcher.methodName
end

-- @return self

function _M:with(...)

    local args = {...}

    if self:isMockerize() then
    end

    self:canDefineParameters()
    self.matcher.parametersMatcher = new(
        'unit.mock.matcher.parameters', args
    )
    
    return self
end

-- @return unit.mock.builder.invocationMocker

function _M:withConsecutive(...)

    self:canDefineParameters()
    self.matcher.parametersMatcher = new(
        'unit.mock.matcher.consecutiveParameters', ...
    )
    
    return self
end

-- @return unit.mock.builder.invocationMocker

function _M:withAnyParameters()

    self:canDefineParameters()
    self.matcher.parametersMatcher = new(
        'unit.mock.matcher.anyParameters'
    )
    
    return self
end

-- @param unit.constraint|string    constraint
-- @return unit.mock.builder.invocationMocker

function _M:method(constraint)

    if self.matcher.methodNameMatcher then
        lx.throw('unit.mock.exception', 'Method name matcher is already defined, cannot redefine')
    end
    if lf.isStr(constraint) and not self.configurableMethods[str.lower(constraint)] then
        lx.throw('unit.mock.exception', fmt('Trying to configure method "%s" which cannot be configured because it does not exist, has not been specified, is final, or is static', constraint))
    end
    self.matcher.methodNameMatcher = new('unit.mock.matcher.methodName', constraint)
    
    return self
end

function _M:isMockerize()

    local mocker = self.collection

    return mocker.mockedClass.lxunitMockerize
end

function _M:once()

    local methodNameMatcher = self.matcher.methodNameMatcher

    local invocationMatcher = new('unit.mock.matcher.invokedCount', 1)
    local matcher = new('unit.mock.matcher', invocationMatcher)
    matcher.methodNameMatcher = methodNameMatcher
    self.collection:removeMatcher(self.matcher)
    self.matcher = matcher
    self.collection:addMatcher(matcher)

    return self
end

function _M:andReturn(value, ...)

    return self:willReturn(value, ...)
end

return _M

