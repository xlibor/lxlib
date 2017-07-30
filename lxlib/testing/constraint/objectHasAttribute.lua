-- This file is part of PHPUnit.
-- (c) Sebastian Bergmann <sebastian@phpunit.de>
-- For the full copyright and license information, please view the LICENSE
-- file that was distributed with this source code.

-- Constraint that asserts that the object it is evaluated for has a given
-- attribute.
-- The attribute name is passed in the constructor.


local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'classHasAttribute'
}

local app, lf, tb, str = lx.kit()

-- Evaluates the constraint for parameter other. Returns true if the
-- constraint is met, false otherwise.
-- @param mixed other Value or object to evaluate.
-- @return bool

function _M.__:matches(other)

    local object = new('reflectionObject', other)
    
    return object:hasProperty(self.attributeName)
end

return _M

