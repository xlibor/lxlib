
local lx, _M, mt = oo{
    _cls_ = '',
    _bond_ = {
        'unit.mock.stub.matcherCollection',
        'unit.mock.invokable',
        'unit.mock.builder.namespace'
    }
}

local app, lf, tb, str, new = lx.kit()
local try, throw = lx.try, lx.throw

function _M:new()

    local this = {
        mockedClass = nil,
        matchers = {},
        builderMap = {},
        configurableMethods = {}
    }
    
    return oo(this, mt)
end

-- @param table configurableMethods

function _M:ctor(mockedClass, configurableMethods)

    self.mockedClass = mockedClass
    self.configurableMethods = configurableMethods
end

-- @param unit.mock.matcher.invocation matcher

function _M:addMatcher(matcher)

    tapd(self.matchers, matcher)
end

function _M:hasMatchers()

    for _, matcher in ipairs(self.matchers) do
        if matcher:hasMatchers() then
            
            return true
        end
    end
    
    return false
end

function _M:removeMatcher(matcher)

    for i, each in ipairs(self.matchers) do
        if each == matcher then
            tb.remove(self.matchers, i)
            break
        end
    end
end

-- @param mixed id
-- @return bool|null

function _M:lookupId(id)

    if self.builderMap[id] then
        
        return self.builderMap[id]
    end
    
    return
end

-- @param mixed                             id
-- @param unit.mock.builder.match           builder

function _M:registerId(id, builder)

    if self.builderMap[id] then
        lx.throw('unit.mock.exception', 'Match builder with id <' .. id .. '> is already registered.')
    end
    self.builderMap[id] = builder
end

-- @param unit.mock.matcher.invocation matcher
-- @return unit.mock.builder.invocationMocker

function _M:expects(matcher)

    return new('unit.mock.builder.invocationMocker',
        self, matcher, self.configurableMethods
    )
end

-- @param unit.mock.invocation invocation
-- @return mixed|null

function _M:invoke(invocation)

    local exception
    local hasReturnValue = false
    local returnValue

    for _, match in ipairs(self.matchers) do
        try(function()
            if match:matches(invocation) then
                value = match:invoked(invocation)
                if not hasReturnValue then
                    returnValue = value
                    hasReturnValue = true
                end
            end
        end)
        :catch(function(e) 
            exception = e
        end)
        :run()
    end
    if exception then
        lx.throw(exception)
    end
    if hasReturnValue then
        
        return returnValue
     elseif str.lower(invocation.methodName) == 'toStr' then
        
        return ''
    end
    
    return invocation:generateReturnValue()
end

-- @param unit.mock.invocation invocation
-- @return bool

function _M:matches(invocation)

    for _, matcher in ipairs(self.matchers) do
        if not matcher:matches(invocation) then
            
            return false
        end
    end
    
    return true
end

-- @return bool

function _M:verify()

    for _, matcher in ipairs(self.matchers) do
        matcher:verify()
    end
end

return _M

