-- This file is part of PHPUnit.
-- (c) Sebastian Bergmann <sebastian@phpunit.de>
-- For the full copyright and license information, please view the LICENSE
-- file that was distributed with this source code.

-- Constraint that asserts that the value it is evaluated for is less than
-- a given value.


local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'unit.constraint'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        value = nil
    }
    
    return oo(this, mt)
end

-- @var numeric
-- @param numeric value

function _M:ctor(value)

    parent.__construct()
    self.value = value
end

-- Evaluates the constraint for parameter other. Returns true if the
-- constraint is met, false otherwise.
-- @param mixed other Value or object to evaluate.
-- @return bool

function _M.__:matches(other)

    return self.value > other
end

-- Returns a string representation of the constraint.
-- @return string

function _M:toStr()

    return 'is less than ' .. self.exporter:export(self.value)
end

return _M

