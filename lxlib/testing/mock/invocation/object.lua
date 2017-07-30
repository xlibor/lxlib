
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'unit.mock.invocation.static'
}

local app, lf, tb, str = lx.kit()

-- @param string        className
-- @param string        methodName
-- @param table         parameters
-- @param string|null   returnType
-- @param object        object
-- @param bool|null     cloneObjects

function _M:ctor(className, methodName, parameters, returnType, object, cloneObjects)

    cloneObjects = cloneObjects or false
    self.__skip = true
    self:__super('ctor', className, methodName, parameters, returnType, cloneObjects)
    self.object = object
end

return _M

