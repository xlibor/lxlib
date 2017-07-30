-- This file is part of PHPUnit.
-- (c) Sebastian Bergmann <sebastian@phpunit.de>
-- For the full copyright and license information, please view the LICENSE
-- file that was distributed with this source code.

-- Constraint that asserts that the class it is evaluated for has a given
-- attribute.
-- The attribute name is passed in the constructor.


local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'unit.constraint'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        attributeName = nil
    }
    
    return oo(this, mt)
end

-- @var string
-- @param string attributeName

function _M:ctor(attributeName)

    parent.__construct()
    self.attributeName = attributeName
end

-- Evaluates the constraint for parameter other. Returns true if the
-- constraint is met, false otherwise.
-- @param mixed other Value or object to evaluate.
-- @return bool

function _M.__:matches(other)

    local class = new('reflectionClass', other)
    
    return class:hasProperty(self.attributeName)
end

-- Returns a string representation of the constraint.
-- @return string

function _M:toStr()

    return fmt('has attribute "%s"', self.attributeName)
end

-- Returns the description of the failure
-- The beginning of failure messages is "Failed asserting that" in most
-- cases. This method should return the second part of that sentence.
-- @param mixed other Evaluated value or object.
-- @return string

function _M.__:failureDescription(other)

    return fmt('%sclass "%s" %s', \lf.isObj(other) and 'object of ' or '', \lf.isObj(other) and \get_class(other) or other, self:toStr())
end

return _M

