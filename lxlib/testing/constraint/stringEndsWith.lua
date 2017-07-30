-- This file is part of PHPUnit.
-- (c) Sebastian Bergmann <sebastian@phpunit.de>
-- For the full copyright and license information, please view the LICENSE
-- file that was distributed with this source code.
-- Constraint that asserts that the string it is evaluated for ends with a given
-- suffix.


local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'unit.constraint'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        suffix = nil
    }
    
    return oo(this, mt)
end

-- @var string
-- @param string suffix

function _M:ctor(suffix)

    parent.__construct()
    self.suffix = suffix
end

-- Evaluates the constraint for parameter other. Returns true if the
-- constraint is met, false otherwise.
-- @param mixed other Value or object to evaluate.
-- @return bool

function _M.__:matches(other)

    return \str.substr(other, 0 - \str.len(self.suffix)) == self.suffix
end

-- Returns a string representation of the constraint.
-- @return string

function _M:toStr()

    return 'ends with "' .. self.suffix .. '"'
end

return _M

