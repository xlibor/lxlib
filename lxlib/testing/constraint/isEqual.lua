
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'unit.constraint'
}

local app, lf, tb, str, new = lx.kit()
local try = lx.try

-- @param mixed         value
-- @param num|null      delta
-- @param int|null      maxDepth
-- @param bool|null     canonicalize
-- @param bool|null     ignoreCase

function _M:ctor(value, delta, maxDepth, canonicalize, ignoreCase)

    ignoreCase = ignoreCase or false
    canonicalize = canonicalize or false
    maxDepth = maxDepth or 10
    delta = delta or 0.0
    self.__skip = true
    self:__super(_M, 'ctor')
 
    self.value = value
    self.delta = delta
    self.maxDepth = maxDepth
    self.canonicalize = canonicalize
    self.ignoreCase = ignoreCase
end

-- Evaluates the constraint for parameter other
-- If returnResult is set to false (the default), an exception is thrown
-- in case of a failure. null is returned otherwise.
-- If returnResult is true, the result of the evaluation is returned as
-- a boolean value instead: true in case of success, false in case of a
-- failure.
-- @param mixed|null        other        Value or object to evaluate.
-- @param string|null       description  Additional information about the test
-- @param bool|null         returnResult Whether to return a result or throw an exception
-- @return mixed

function _M:evaluate(other, description, returnResult)

    returnResult = returnResult or false
    description = description or ''

    if type(self.value) == type(other) then
        if self.value == other then
        
            return true
        end
    end

    local comparator = new('unit.comparator')
    try(function()
        comparator:assertEquals(self.value, other, self.delta, self.canonicalize, self.ignoreCase)
    end)
    :catch('unit.comparisonFailure', function(e) 
        if returnResult then
            
            return false
        end

        lx.throw('unit.expectationFailedException',
            str.trim(description .. "\n" .. e:getMessage()), e
        )
    end)
    :run()
    
    return true
end

-- Returns a string representation of the constraint.
-- @return string

function _M:toStr()

    local delta = ''
    if lf.isStr(self.value) then
        if str.strpos(self.value, "\n") ~= false then
            
            return 'is equal to <text>'
        end
        
        return fmt('is equal to <string:%s>', self.value)
    end
    if self.delta ~= 0 then
        delta = fmt(' with delta <%F>', self.delta)
    end
    
    return fmt('is equal to %s%s', self.exporter:export(self.value), delta)
end

return _M

