
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'unit.constraint'
}

local app, lf, tb, str, new = lx.kit()

-- Creates a new constraint.
-- @param string value

function _M:ctor(value)

    self.__skip = true
    self:__super(_M, 'ctor')
    self.value = value
end

-- Evaluates the constraint for parameter other. Returns true if the
-- constraint is met, false otherwise.
-- This method can be overridden to implement the evaluation algorithm.
-- @param mixed other Value or object to evaluate.
-- @return bool

function _M.__:matches(other)

    local error, recodedOther = self:canonicalizeJson(other)
    if error then
        
        return false
    end
    local error, recodedValue = self:canonicalizeJson(self.value)
    if error then
        
        return false
    end
    
    return recodedOther == recodedValue
end

-- Throws an exception for the given compared value and test description
-- @param mixed             other             Evaluated value or object.
-- @param string            description       Additional information about the test
-- @param ComparisonFailure comparisonFailure
-- @throws ExpectationFailedException

function _M.__:fail(other, description, comparisonFailure)

    if comparisonFailure == nil then
        local error = self:canonicalizeJson(other)
        if error then
            self:__super(_M, 'fail', other, description)
            
            return
        end
        local error = self:canonicalizeJson(self.value)
        if error then
            self:__super(_M, 'fail', other, description)
            
            return
        end
        comparisonFailure = new('unit.comparisonFailure',
            lf.jsde(self.value), lf.jsde(other), other,
            self.value, false,
            'Failed asserting that two json values are equal.'
        )
    end

    self:__super(_M, 'fail', other, description, comparisonFailure)
end

-- To allow comparison of JSON strings, first process them into a consistent
-- format so that they can be compared as strings.
-- @return bool error The error parameter is used
-- @return mixed|null canonicalized_json

-- to indicate an error decoding the json.  This is used to avoid ambiguity
-- with JSON strings consisting entirely of 'null' or 'false'.

function _M.__:canonicalizeJson(json)

    local decodedJson = lx.json.safeDecode(json)
    if not decodedJson then
        
        return true, nil
    end

    local reencodedJson = lf.jsen(decodedJson)
    
    return false, reencodedJson
end
 
-- Returns a string representation of the object.
-- @return string

function _M:toStr()

    return fmt('matches JSON string "%s"', self.value)
end

return _M

