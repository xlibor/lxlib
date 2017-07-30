
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str, new = lx.kit()

function _M:new()

    local this = {
        testCase = nil,
        type = nil,
        methods = {},
        methodsExcept = {},
        mockClassName = '',
        constructorArgs = {},
        originalConstructor = true,
        originalClone = true,
        autoload = true,
        cloneArguments = false,
        callOriginalMethods = false,
        proxyTarget = nil,
        allowMockingUnknownTypes = true,
        generator = nil
    }
    
    return oo(this, mt)
end
 
-- @param unit.testCase         testCase
-- @param table|string          type

function _M:ctor(testCase, type)

    self.testCase = testCase
    self.type = type
    self.generator = new('unit.mock.generator')
end

-- Creates a mock object using a fluent interface.
-- @return unit.mock.mockObject

function _M:getMock()

    local object = self.generator:getMock(
        self.type, self.methods, self.constructorArgs,
        self.mockClassName, self.originalConstructor,
        self.originalClone, self.autoload, self.cloneArguments,
        self.callOriginalMethods, self.proxyTarget,
        self.allowMockingUnknownTypes
    )
    
    self.testCase:registerMockObject(object)
    
    return object
end

-- Creates a mock object for an abstract class using a fluent interface.
-- @return unit.mock.mockObject

function _M:getMockForAbstractClass()

    local object = self.generator:getMockForAbstractClass(self.type, self.constructorArgs, self.mockClassName, self.originalConstructor, self.originalClone, self.autoload, self.methods, self.cloneArguments)
    self.testCase:registerMockObject(object)
    
    return object
end

-- Creates a mock object for a trait using a fluent interface.
-- @return unit.mock.mockObject

function _M:getMockForTrait()

    local object = self.generator:getMockForTrait(self.type, self.constructorArgs, self.mockClassName, self.originalConstructor, self.originalClone, self.autoload, self.methods, self.cloneArguments)
    self.testCase:registerMockObject(object)
    
    return object
end

-- Specifies the subset of methods to mock. Default is to mock all of them.
-- @param table|null methods
-- @return unit.mock.mockBuilder

function _M:setMethods(methods)

    self.methods = methods
    
    return self
end

-- Specifies the subset of methods to not mock. Default is to mock all of them.
-- @param table methods
-- @return unit.mock.mockBuilder

function _M:setMethodsExcept(methods)

    methods = methods or {}
    self.methodsExcept = methods
    self:setMethods(tb.diff(self.generator:getClassMethods(self.type), self.methodsExcept))
    
    return self
end

-- Specifies the arguments for the constructor.
-- @param table args
-- @return unit.mock.mockBuilder

function _M:setConstructorArgs(args)

    self.constructorArgs = args
    
    return self
end

-- Specifies the name for the mock class.
-- @param string name
-- @return unit.mock.mockBuilder

function _M:setMockClassName(name)

    self.mockClassName = name
    
    return self
end

-- Disables the invocation of the original constructor.
-- @return unit.mock.mockBuilder

function _M:disableOriginalConstructor()

    self.originalConstructor = false
    
    return self
end

-- Enables the invocation of the original constructor.
-- @return unit.mock.mockBuilder

function _M:enableOriginalConstructor()

    self.originalConstructor = true
    
    return self
end

-- Disables the invocation of the original clone constructor.
-- @return unit.mock.mockBuilder

function _M:disableOriginalClone()

    self.originalClone = false
    
    return self
end

-- Enables the invocation of the original clone constructor.
-- @return unit.mock.mockBuilder

function _M:enableOriginalClone()

    self.originalClone = true
    
    return self
end

-- Disables the use of class autoloading while creating the mock object.
-- @return unit.mock.mockBuilder

function _M:disableAutoload()

    self.autoload = false
    
    return self
end

-- Enables the use of class autoloading while creating the mock object.
-- @return unit.mock.mockBuilder

function _M:enableAutoload()

    self.autoload = true
    
    return self
end

-- Disables the cloning of arguments passed to mocked methods.
-- @return unit.mock.mockBuilder

function _M:disableArgumentCloning()

    self.cloneArguments = false
    
    return self
end

-- Enables the cloning of arguments passed to mocked methods.
-- @return unit.mock.mockBuilder

function _M:enableArgumentCloning()

    self.cloneArguments = true
    
    return self
end

-- Enables the invocation of the original methods.
-- @return unit.mock.mockBuilder

function _M:enableProxyingToOriginalMethods()

    self.callOriginalMethods = true
    
    return self
end

-- Disables the invocation of the original methods.
-- @return unit.mock.mockBuilder

function _M:disableProxyingToOriginalMethods()

    self.callOriginalMethods = false
    self.proxyTarget = nil
    
    return self
end

-- Sets the proxy target.
-- @param object object
-- @return unit.mock.mockBuilder

function _M:setProxyTarget(object)

    self.proxyTarget = object
    
    return self
end

-- @return unit.mock.mockBuilder

function _M:allowMockingUnknownTypes()

    self.allowMockingUnknownTypes = true
    
    return self
end

-- @return unit.mock.mockBuilder

function _M:disallowMockingUnknownTypes()

    self.allowMockingUnknownTypes = false
    
    return self
end

return _M

