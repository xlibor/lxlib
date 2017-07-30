
local lx, _M, mt = oo{
    _cls_ = '',
    _bond_ = 'unit.mock.mockObject'
}

local app, lf, tb, str, new = lx.kit()

function _M:new()

    local this = {
        lxunitInvocationMocker = false,
        lxunitMockerize = false,
        lxunitMethodArgs = {},
    }

    return oo(this, mt)
end

function _M:ctor(methods, className, configurable)

    self.lxunitMockedMethods = methods
    self.lxunitClassName = className
    self.lxunitConfigurable = configurable

end

function _M:lxunitSetOriginalObject(originalObject)

    self.lxunitOriginalObject = originalObject
end

function _M:lxunitGetInvocationMocker()

    if not self.lxunitInvocationMocker then
        self.lxunitInvocationMocker = new(
            'unit.mock.invocationMocker',
            self, self.lxunitConfigurable
        )
    end

    return self.lxunitInvocationMocker
end

function _M:lxunitHasMatchers()

    return self:lxunitGetInvocationMocker():hasMatchers()
end

function _M:lxunitVerify(unsetInvocationMocker)

    unsetInvocationMocker = lf.needTrue(unsetInvocationMocker)
    self:lxunitGetInvocationMocker():verify()

    if unsetInvocationMocker then
        self.lxunitInvocationMocker = nil
    end
end

function _M:lxunitSetMethodArgs(methodName, ...)

    self.lxunitMethodArgs[methodName] = {...}
end

function _M:_get_(key)

end

function _M:expects(matcher)

    return self:lxunitGetInvocationMocker():expects(matcher)
end

function _M:method(name)

    local any = new('unit.mock.matcher.anyInvokedCount')
    local expects = self:expects(any)

    return lf.call({expects, 'method'}, name)
end

function _M:shouldReceive(methodName)

    return self:method(methodName)
end

function _M.__:getMethodArgs(methodName)

    return self.lxunitMethodArgs[methodName]
end

function _M:_run_(method)

    local className = self.lxunitClassName

    return function(self, ...)
        local result

        local args, count = lf.getArgs(...)

        local returnType = ''
        result = self:lxunitGetInvocationMocker():invoke(
            new('unit.mock.invocation.object',
                className, method, args, returnType,
                self
            )
        )

        return result
    end
end

return _M


