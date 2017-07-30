-- This file is part of PHPUnit.
-- (c) Sebastian Bergmann <sebastian@phpunit.de>
-- For the full copyright and license information, please view the LICENSE
-- file that was distributed with this source code.
-- Constraint that asserts that the string it is evaluated for matches
-- a regular expression.
-- Checks a given value using the Perl Compatible Regular Expression extension
-- in PHP. The pattern is matched by executing preg_match().
-- The pattern string passed in the constructor.


local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'unit.constraint'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        pattern = nil
    }
    
    return oo(this, mt)
end

-- @var string
-- @param string pattern

function _M:ctor(pattern)

    parent.__construct()
    self.pattern = pattern
end

-- Evaluates the constraint for parameter other. Returns true if the
-- constraint is met, false otherwise.
-- @param mixed other Value or object to evaluate.
-- @return bool

function _M.__:matches(other)

    return \str.rematch(other, self.pattern) > 0
end

-- Returns a string representation of the constraint.
-- @return string

function _M:toStr()

    return fmt('matches PCRE pattern "%s"', self.pattern)
end

return _M

