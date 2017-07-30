-- This file is part of PHPUnit.
-- (c) Sebastian Bergmann <sebastian@phpunit.de>
-- For the full copyright and license information, please view the LICENSE
-- file that was distributed with this source code.

-- Constraint that evaluates against a specified closure.


local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'unit.constraint'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        callback = nil
    }
    
    return oo(this, mt)
end

-- @param func callback
-- @throws \PHPUnit\Framework\Exception

function _M:ctor(callback)

    if not \lf.isCallable(callback) then
        InvalidArgument(1, 'callable')
    end
    parent.__construct()
    self.callback = callback
end

-- Evaluates the constraint for parameter value. Returns true if the
-- constraint is met, false otherwise.
-- @param mixed other Value or object to evaluate.
-- @return bool

function _M.__:matches(other)

    return \lf.call(self.callback, other)
end

-- Returns a string representation of the constraint.
-- @return string

function _M:toStr()

    return 'is accepted by specified callback'
end

return _M

