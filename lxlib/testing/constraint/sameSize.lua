-- This file is part of PHPUnit.
-- (c) Sebastian Bergmann <sebastian@phpunit.de>
-- For the full copyright and license information, please view the LICENSE
-- file that was distributed with this source code.

local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'count'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        expectedCount = nil
    }
    
    return oo(this, mt)
end

-- @var int
-- @param \Countable|\eachable\|array expected

function _M:ctor(expected)

    parent.__construct(self:getCountOf(expected))
end

return _M

