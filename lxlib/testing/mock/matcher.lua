
local lx, _M, mt = oo{
    _cls_ = '',
    _bond_ = 'unit.mock.matcher.invocation'
}

local app, lf, tb, str, new = lx.kit()
local try, throw = lx.try, lx.throw

local TestFailure = lx.use('unit.testFailure')

function _M:new()

    local this = {
        invocationMatcher = nil,
        afterMatchBuilderId = nil,
        afterMatchBuilderIsInvoked = false,
        methodNameMatcher = nil,
        parametersMatcher = nil,
        stub = nil
    }
    
    return oo(this, mt)
end

-- @param unit.mock.matcher.invocation invocationMatcher

function _M:ctor(invocationMatcher)

    self.invocationMatcher = invocationMatcher
end

-- @return string

function _M:toStr()

    local list = {}
    if self.invocationMatcher then
        tapd(list, self.invocationMatcher:toStr())
    end
    if self.methodNameMatcher then
        tapd(list, 'where ' .. self.methodNameMatcher:toStr())
    end
    if self.parametersMatcher then
        tapd(list, 'and ' .. self.parametersMatcher:toStr())
    end
    if self.afterMatchBuilderId then
        tapd(list, 'after ' .. self.afterMatchBuilderId)
    end
    if self.stub then
        tapd(list, 'will ' .. self.stub:toStr())
    end
    
    return str.join(list, ' ')
end

-- @param unit.mock.invocation invocation
-- @return mixed|null

function _M:invoked(invocation)

    local matcher
    local builder
    if not self.invocationMatcher then
        throw('unit.mock.exception', 'No invocation matcher is set')
    end
    if not self.methodNameMatcher then
        throw('unit.mock.exception', 'No method matcher is set')
    end
    if self.afterMatchBuilderId then
        builder = invocation.object:lxunitGetInvocationMocker():lookupId(self.afterMatchBuilderId)
        if not builder then
            throw('unit.mock.exception', fmt('No builder found for match builder identification <%s>', self.afterMatchBuilderId))
        end
        matcher = builder:getMatcher()
        if matcher and matcher.invocationMatcher:hasBeenInvoked() then
            self.afterMatchBuilderIsInvoked = true
        end
    end
    self.invocationMatcher:invoked(invocation)
    try(function()
        if self.parametersMatcher and not self.parametersMatcher:matches(invocation) then
            self.parametersMatcher:verify()
        end
    end)
    :catch('unit.expectationFailedException', function(e) 
        throw('unit.expectationFailedException',
            fmt("Expectation failed for %s when %s\n%s",
                self.methodNameMatcher:toStr(),
                self.invocationMatcher:toStr(),
                e:getMessage()
            ),
            e:getComparisonFailure()
        )
    end)
    :run()

    if self.stub then
        
        return self.stub:invoke(invocation)
    end

    return invocation:generateReturnValue()
end

-- @param unit.mock.invocation invocation
-- @return bool

function _M:matches(invocation)

    local matcher
    local builder
    if self.afterMatchBuilderId then
        builder = invocation.object:lxunitGetInvocationMocker():lookupId(self.afterMatchBuilderId)
        if not builder then
            throw('unit.mock.exception', fmt('No builder found for match builder identification <%s>', self.afterMatchBuilderId))
        end
        matcher = builder:getMatcher()
        if not matcher then
            
            return false
        end
        if not matcher.invocationMatcher:hasBeenInvoked() then
            
            return false
        end
    end
    if not self.invocationMatcher then
        throw('unit.mock.exception', 'No invocation matcher is set')
    end
    if not self.methodNameMatcher then
        throw('unit.mock.exception', 'No method matcher is set')
    end
    if not self.invocationMatcher:matches(invocation) then
        
        return false
    end

    local ok, ret = 
    try(function()
        if not self.methodNameMatcher:matches(invocation) then
            
            return false
        end
    end)
    :catch('unit.expectationFailedException', function(e) 
        throw('unit.expectationFailedException',
            fmt("Expectation failed for %s when %s\n%s",
                self.methodNameMatcher:toStr(),
                self.invocationMatcher:toStr(),
                e:getMessage()
            ),
            e:getComparisonFailure()
        )
    end)
    :run()
    
    if ok then
        if lf.isFalse(ret) then
            return false
        end
    end
    
    return true
end

function _M:verify()

    if not self.invocationMatcher then
        throw('unit.mock.exception', 'No invocation matcher is set')
    end
    if not self.methodNameMatcher then
        throw('unit.mock.exception', 'No method matcher is set')
    end
    try(function()
        self.invocationMatcher:verify()
        if not self.parametersMatcher then
            self.parametersMatcher = new('unit.mock.matcher.anyParameters')
        end
        invocationIsAny = self.invocationMatcher:__is('unit.mock.matcher.anyInvokedCount')
        invocationIsNever = self.invocationMatcher:__is('unit.mock.matcher.invokedCount') and self.invocationMatcher:isNever()
        if not invocationIsAny and not invocationIsNever then
            self.parametersMatcher:verify()
        end
    end)
    :catch('unit.expectationFailedException', function(e) 
        throw('unit.expectationFailedException',
            fmt("Expectation failed for %s when %s.\n%s",
                self.methodNameMatcher:toStr(),
                self.invocationMatcher:toStr(),
                TestFailure.exceptiontoStr(e)))
    end)
    :run()
end

function _M:hasMatchers()

    if self.invocationMatcher and not self.invocationMatcher:__is('unit.mock.matcher.anyInvokedCount') then
        
        return true
    end
    
    return false
end

return _M

