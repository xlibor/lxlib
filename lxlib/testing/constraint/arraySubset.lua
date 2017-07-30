-- This file is part of PHPUnit.
-- (c) Sebastian Bergmann <sebastian@phpunit.de>
-- For the full copyright and license information, please view the LICENSE
-- file that was distributed with this source code.
-- Constraint that asserts that the table it is evaluated for has a specified subset.
-- Uses table_replace_recursive() to check if a key value subset is part of the
-- subject table.


local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'unit.constraint'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        subset = nil,
        strict = nil
    }
    
    return oo(this, mt)
end

-- @var table|\eachable
-- @var bool
-- @param table|\eachable subset
-- @param bool               strict Check for object identity

function _M:ctor(subset, strict)

    strict = strict or false
    parent.__construct()
    self.strict = strict
    self.subset = subset
end

-- Evaluates the constraint for parameter other. Returns true if the
-- constraint is met, false otherwise.
-- @param table|\eachable other Array or eachable object to evaluate.
-- @return bool

function _M.__:matches(other)

    --type cast other & this->subset as an table to allow
    --support in standard table functions.
    other = self:toArray(other)
    self.subset = self:toArray(self.subset)
    local patched = \array_replace_recursive(other, self.subset)
    if self.strict then
        
        return other == patched
    end
    
    return other == patched
end

-- Returns a string representation of the constraint.
-- @return string

function _M:toStr()

    return 'has the subset ' .. self.exporter:export(self.subset)
end

-- Returns the description of the failure
-- The beginning of failure messages is "Failed asserting that" in most
-- cases. This method should return the second part of that sentence.
-- @param mixed other Evaluated value or object.
-- @return string

function _M.__:failureDescription(other)

    return 'an array ' .. self:toStr()
end

-- @param table|\eachable other
-- @return table

function _M.__:toArray(other)

    if \lf.isTbl(other) then
        
        return other
    end
    if other:__is('\ArrayObject') then
        
        return other:getArrayCopy()
    end
    if other:__is('\eachable') then
        
        return \iterator_to_array(other)
    end
    -- Keep BC even if we know that table would not be the expected one
    
    return lf.needList(other)
end

return _M

