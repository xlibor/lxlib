-- This file is part of PHPUnit.
-- (c) Sebastian Bergmann <sebastian@phpunit.de>
-- For the full copyright and license information, please view the LICENSE
-- file that was distributed with this source code.
-- Constraint that asserts that the string it is evaluated for begins with a
-- given prefix.


local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'unit.constraint'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        prefix = nil
    }
    
    return oo(this, mt)
end

-- @var string
-- @param string prefix

function _M:ctor(prefix)

    parent.__construct()
    self.prefix = prefix
end

-- Evaluates the constraint for parameter other. Returns true if the
-- constraint is met, false otherwise.
-- @param mixed other Value or object to evaluate.
-- @return bool

function _M.__:matches(other)

    return \str.strpos(other, self.prefix) == 0
end

-- Returns a string representation of the constraint.
-- @return string

function _M:toStr()

    return 'starts with "' .. self.prefix .. '"'
end

return _M

