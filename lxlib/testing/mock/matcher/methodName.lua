
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'unit.mock.matcher.statelessInvocation'
}

local app, lf, tb, str, new = lx.kit()
local InvalidArgument = lx.use('unit.invalidArgumentHelper').factory

function _M:new()

    local this = {
        constraint = nil,
        methodName = nil,
    }
    
    return oo(this, mt)
end

-- @param unit.constraint|string constraint

function _M:ctor(constraint)

    if not lf.isStr(constraint) then
        if not lf.isObj(constraint) or not constraint:__is('unit.constraint') then
            InvalidArgument(1, 'string')
        end
    else
        self.methodName = constraint
        constraint = new('unit.constraint.isEqual', constraint, 0, 10, false, true)
    end

    self.constraint = constraint
end

-- @return string

function _M:toStr()

    return 'method name ' .. self.constraint:toStr()
end

-- @param unit.mock.invocation invocation
-- @return bool

function _M:matches(invocation)

    return self.constraint:evaluate(invocation.methodName, '', true)
end

return _M

