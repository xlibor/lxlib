
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'unit.mock.matcher.statelessInvocation'
}

local app, lf, tb, str, new = lx.kit()
local try = lx.try

function _M:new()

    local this = {
        parameters = {},
        invocation = nil,
        parameterVerificationResult = nil
    }
    
    return oo(this, mt)
end

-- @param table parameters

function _M:ctor(parameters)

    local parameter
    for _, parameter in ipairs(parameters) do
        if not lf.isA(parameter, 'unit.constraint') then
            parameter = new('unit.constraint.isEqual', parameter)
        end
        tapd(self.parameters, parameter)
    end
end

-- @return string

function _M:toStr()

    local text = 'with parameter'
    for index, parameter in ipairs(self.parameters) do
        if index > 0 then
            text = text .. ' and'
        end
        text = text .. ' ' .. index .. ' ' .. parameter:toStr()
    end
    
    return text
end

-- @param unit.mock.invocation invocation
-- @return bool|null

function _M:matches(invocation)

    self.invocation = invocation
    self.parameterVerificationResult = nil
    
    local ok, ret = try(function()
        self.parameterVerificationResult = self:verify()
        
        return self.parameterVerificationResult
    end)
    :catch('unit.expectationFailedException', function(e) 
        self.parameterVerificationResult = e
        lx.throw(e)
    end)
    :run()

    if ok then
        return ret
    end

end

-- Checks if the invocation invocation matches the current rules. If it
-- does the matcher will get the invoked() method called which should check
-- if an expectation is met.
-- @return bool

function _M:verify()

    local message
    if self.parameterVerificationResult then
        
        return self:guardAgainstDuplicateEvaluationOfParameterConstraints()
    end
    if not self.invocation then
        lx.throw('unit.expectationFailedException', 'Mocked method does not exist.')
    end
    if #self.invocation.parameters < #self.parameters then
        message = 'Parameter count for invocation %s is too low.'

        if #self.parameters == 1 and self.parameters[1].__cls == 'unit.constraint.isAnything' then
            message = message .. "\nTo allow 0 or more parameters with any value, omit :with() or use :withAnyParameters() instead."
        end
        lx.throw('unit.expectationFailedException', fmt(message, self.invocation:toStr()))
    end
    for i, parameter in ipairs(self.parameters) do
        parameter:evaluate(self.invocation.parameters[i],
            fmt('Parameter %s for invocation %s does not match expected ' .. 'value.',
                i, self.invocation:toStr()
            )
        )
    end
    
    return true
end

-- @return bool

function _M.__:guardAgainstDuplicateEvaluationOfParameterConstraints()

    if self.parameterVerificationResult:__is('exception') then
        lx.throw(self.parameterVerificationResult)
    end
    
    return self.parameterVerificationResult
end

return _M

