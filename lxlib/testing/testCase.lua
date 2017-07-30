    
local lx, _M, mt = oo{
    _cls_       = '',
    _ext_       = 'unit.assert',
    _bond_      = {'unit.test', 'strable'},
    _static_    = {}
}

local app, lf, tb, str, new = lx.kit()
local try, throw = lx.try, lx.throw

function _M:new()

    local this = {
        backupGlobals = nil,
        backupGlobalsBlacklist = {},
        backupStaticAttributes = nil,
        backupStaticAttributesBlacklist = {},
        runTestInSeparateProcess = nil,
        preserveGlobalState = true,
        inIsolation = false,
        data = nil,
        dataName = nil,
        useErrorHandler = nil,
        expectedException = nil,
        expectedExceptionMessage = '',
        expectedExceptionMessageRegExp = '',
        expectedExceptionCode = nil,
        name = nil,
        dependencies = {},
        dependencyInput = {},
        iniSettings = {},
        locale = {},
        mockObjects = {},
        mockObjectGenerator = nil,
        status = nil,
        statusMessage = '',
        numAssertions = 0,
        result = nil,
        testResult = nil,
        output = '',
        outputExpectedRegex = nil,
        outputExpectedString = nil,
        outputCallback = false,
        outputBufferingActive = false,
        outputBufferingLevel = nil,
        snapshot = nil,
        prophet = nil,
        beStrictAboutChangesToGlobalState = false,
        registerMockObjectsFromTestArgumentsRecursively = false,
        warnings = {},
        groups = {},
        doesNotPerformAssertions = false
    }
    
    return oo(this, mt)
end

function _M:ctor(name, data, dataName)

    dataName = dataName or ''
    data = data or {}
    if name then
        self:setName(name)
    end
    self.data = data
    self.dataName = dataName
end

-- Returns a string representation of the test case.
-- @return string

function _M:toStr()

    local class = self.__cls
    local buffer = fmt('%s.%s', class, self:getName(false))
    
    return buffer .. self:getDataSetAsString()
end

-- Counts the number of test cases executed by run(TestResult result).
-- @return int

function _M:count()

    return 1
end

function _M:getGroups()

    return self.groups
end

-- @param table groups

function _M:setGroups(groups)

    self.groups = groups
end

-- Returns the annotations for this test.
-- @return table

function _M:getAnnotations()

    return parseTestMethodAnnotations(self, self.name)
end

-- Gets the name of a TestCase.
-- @param bool|null     withDataSet
-- @return string

function _M:getName(withDataSet)

    withDataSet = lf.needTrue(withDataSet)
    if withDataSet then
        
        return self.name .. self:getDataSetAsString(false)
    end
    
    return self.name
end

-- Returns the size of the test.
-- @return int

function _M:getSize()

    return utilTest.getSize(self.__cls, self:getName(false))
end

-- @return bool

function _M:hasSize()

    return self:getSize() ~= utilTest.UNKNOWN
end

-- @return bool

function _M:isSmall()

    return self:getSize() == utilTest.SMALL
end

-- @return bool

function _M:isMedium()

    return self:getSize() == utilTest.MEDIUM
end

-- @return bool

function _M:isLarge()

    return self:getSize() == utilTest.LARGE
end

-- @return string

function _M:getActualOutput()

    if not self.outputBufferingActive then
        
        return self.output
    end
    
    return ob_get_contents()
end

-- @return bool

function _M:hasOutput()

    if str.len(self.output) == 0 then
        
        return false
    end
    if self:hasExpectationOnOutput() then
        
        return false
    end
    
    return true
end

-- @return bool

function _M:doesNotPerformAssertions()

    return self.doesNotPerformAssertions
end

-- @param string expectedRegex
-- @throws Exception

function _M:expectOutputRegex(expectedRegex)

    if self.outputExpectedString ~= nil then
        lx.throw('exception')
    end
    if lf.isStr(expectedRegex) or not expectedRegex then
        self.outputExpectedRegex = expectedRegex
    end
end

-- @param string expectedString

function _M:expectOutputString(expectedString)

    if self.outputExpectedRegex ~= nil then
        lx.throw('exception')
    end
    if lf.isStr(expectedString) or not expectedString then
        self.outputExpectedString = expectedString
    end
end

-- @return bool

function _M:hasExpectationOnOutput()

    return lf.isStr(self.outputExpectedString) or lf.isStr(self.outputExpectedRegex)
end

-- @return null|string

function _M:getExpectedException()

    return self.expectedException
end

-- @return null|int|string

function _M:getExpectedExceptionCode()

    return self.expectedExceptionCode
end

-- @return string

function _M:getExpectedExceptionMessage()

    return self.expectedExceptionMessage
end

-- @return string

function _M:getExpectedExceptionMessageRegExp()

    return self.expectedExceptionMessageRegExp
end

-- @param string exception

function _M:expectException(exception)

    if not lf.isStr(exception) then
        InvalidArgument(1, 'string')
    end
    self.expectedException = exception
end

-- @param int|string code
-- @throws Exception

function _M:expectExceptionCode(code)

    if not self.expectedException then
        self.expectedException = Exception.__cls
    end
    if not lf.isNum(code) and not lf.isStr(code) then
        InvalidArgument(1, 'integer or string')
    end
    self.expectedExceptionCode = code
end

-- @param string message
-- @throws Exception

function _M:expectExceptionMessage(message)

    if not self.expectedException then
        self.expectedException = Exception.__cls
    end
    if not lf.isStr(message) then
        InvalidArgument(1, 'string')
    end
    self.expectedExceptionMessage = message
end

-- @param string messageRegExp
-- @throws Exception

function _M:expectExceptionMessageRegExp(messageRegExp)

    if not lf.isStr(messageRegExp) then
        InvalidArgument(1, 'string')
    end
    self.expectedExceptionMessageRegExp = messageRegExp
end

-- @param bool flag

function _M:setRegisterMockObjectsFromTestArgumentsRecursively(flag)

    if not lf.isBool(flag) then
        InvalidArgument(1, 'boolean')
    end
    self.registerMockObjectsFromTestArgumentsRecursively = flag
end

function _M.__:setExpectedExceptionFromAnnotation()

    try(function()
        expectedException = utilTest.getExpectedException(self.__cls, self.name)
        if expectedException ~= false then
            self:expectException(expectedException['class'])
            if expectedException['code'] ~= nil then
                self:expectExceptionCode(expectedException['code'])
            end
            if expectedException['message'] ~= '' then
                self:expectExceptionMessage(expectedException['message'])
             elseif expectedException['message_regex'] ~= '' then
                self:expectExceptionMessageRegExp(expectedException['message_regex'])
            end
        end
    end)
    :catch('reflectionException', function(e) 
    end)
    :run()
end

-- @param bool useErrorHandler

function _M:setUseErrorHandler(useErrorHandler)

    self.useErrorHandler = useErrorHandler
end

function _M.__:setUseErrorHandlerFromAnnotation()

    try(function()
        useErrorHandler = utilTest.getErrorHandlerSettings(self.__cls, self.name)
        if useErrorHandler ~= nil then
            self:setUseErrorHandler(useErrorHandler)
        end
    end)
    :catch('reflectionException', function(e) 
    end)
    :run()
end

function _M.__:checkRequirements()

    if not self.name or not self:__has(self.name) then
        
        return
    end
    local missingRequirements = utilTest.getMissingRequirements(self.__cls, self.name)
    if not lf.isEmpty(missingRequirements) then
        self:markTestSkipped(str.join(missingRequirements, PHP_EOL))
    end
end

-- Returns the status of this test.
-- @return int

function _M:getStatus()

    return self.status
end

function _M:markAsRisky()

    self.status = BaseTestRunner.STATUS_RISKY
end

-- Returns the status message of this test.
-- @return string

function _M:getStatusMessage()

    return self.statusMessage
end

-- Returns whether or not this test has failed.
-- @return bool

function _M:hasFailed()

    local status = self:getStatus()
    
    return status == BaseTestRunner.STATUS_FAILURE or status == BaseTestRunner.STATUS_ERROR
end

-- Runs the test case and collects the results in a TestResult object.
-- If no TestResult object is passed a new one will be created.
-- @param unit.testResult result
-- @return unit.testResult
-- @throws Exception

function _M:run(result)

    if not result then
        result = self:createResult()
    end

    result:run(self)

    self.result = nil
    
    return result
end

-- Runs the bare test sequence.

function _M:runBare()

    local excp

    self.numAssertions = 0
    local hookMethods = {
        beforeClass = {'setUpBeforeClass'},
        before = {'setUp'},
        after = {'tearDown'},
        afterClass = {'tearDownAfterClass'}
    }

    try(function()
        for _, method in ipairs(hookMethods.beforeClass) do
            self[method](self)
        end

        for _, method in ipairs(hookMethods.before) do
            self[method](self)
        end

        self.testResult = self:runTest()
    end)
    :catch('unit.assertionFailedError', function(e)
        excp = e
    end)
    :run()

    try(function()
        for _, method in ipairs(hookMethods.after) do
            self[method](self)
        end

        for _, method in ipairs(hookMethods.afterClass) do
            self[method](self)
        end
    end)
    :catch('throwable', function(e)
        excp = e
    end)
    :run()

    if excp then
        lx.throw(excp)
    end
end

-- Override to run the test and assert its state.
-- @return mixed|null

function _M:runTest()

    local method = self[self.name]
    local testResult = method(self)

    return testResult
end

-- Verifies the mock object expectations.

function _M.__:verifyMockObjects()

    for _, mockObject in pairs(self.mockObjects) do
        if mockObject:__phpunit_hasMatchers() then
            self.numAssertions = self.numAssertions + 1
        end
        mockObject:__phpunit_verify(self:shouldInvocationMockerBeReset(mockObject))
    end
    if self.prophet ~= nil then
        try(function()
            self.prophet:checkPredictions()
        end)
        :catch('Throwable', function(t) 
        end)
        :run()
        for _, objectProphecy in pairs(self.prophet:getProphecies()) do
            for _, methodProphecies in pairs(objectProphecy:getMethodProphecies()) do
                for _, methodProphecy in pairs(methodProphecies) do
                    self.numAssertions = self.numAssertions + #methodProphecy:getCheckedPredictions()
                end
            end
        end
        if t then
            lx.throw(t)
        end
    end
end

-- Sets the name of a TestCase.
-- @param  string name

function _M:setName(name)

    self.name = name
end

-- Sets the dependencies of a TestCase.
-- @param table dependencies

function _M:setDependencies(dependencies)

    self.dependencies = dependencies
end

-- Returns true if the tests has dependencies
-- @return bool

function _M:hasDependencies()

    return #self.dependencies > 0
end

-- Sets
-- @param table dependencyInput

function _M:setDependencyInput(dependencyInput)

    self.dependencyInput = dependencyInput
end

-- @param bool beStrictAboutChangesToGlobalState

function _M:setBeStrictAboutChangesToGlobalState(beStrictAboutChangesToGlobalState)

    self.beStrictAboutChangesToGlobalState = beStrictAboutChangesToGlobalState
end

-- Calling this method in setUp() has no effect!
-- @param bool backupGlobals

function _M:setBackupGlobals(backupGlobals)

    if not self.backupGlobals and lf.isBool(backupGlobals) then
        self.backupGlobals = backupGlobals
    end
end

-- Calling this method in setUp() has no effect!
-- @param bool backupStaticAttributes

function _M:setBackupStaticAttributes(backupStaticAttributes)

    if not self.backupStaticAttributes and lf.isBool(backupStaticAttributes) then
        self.backupStaticAttributes = backupStaticAttributes
    end
end

-- @param bool runTestInSeparateProcess
-- @throws Exception

function _M:setRunTestInSeparateProcess(runTestInSeparateProcess)

    if lf.isBool(runTestInSeparateProcess) then
        if self.runTestInSeparateProcess == nil then
            self.runTestInSeparateProcess = runTestInSeparateProcess
        end
     else 
        InvalidArgument(1, 'boolean')
    end
end

-- @param bool preserveGlobalState
-- @throws Exception

function _M:setPreserveGlobalState(preserveGlobalState)

    if lf.isBool(preserveGlobalState) then
        self.preserveGlobalState = preserveGlobalState
     else 
        InvalidArgument(1, 'boolean')
    end
end

-- @param bool inIsolation
-- @throws Exception

function _M:setInIsolation(inIsolation)

    if lf.isBool(inIsolation) then
        self.inIsolation = inIsolation
     else 
        InvalidArgument(1, 'boolean')
    end
end

-- @return bool

function _M:isInIsolation()

    return self.inIsolation
end

-- @return mixed|null

function _M:getResult()

    return self.testResult
end

-- @param mixed result

function _M:setResult(result)

    self.testResult = result
end

-- @param func callback
-- @throws Exception

function _M:setOutputCallback(callback)

    if not lf.isCallable(callback) then
        InvalidArgument(1, 'callback')
    end
    self.outputCallback = callback
end

-- @return unit.testResult

function _M:getTestResultObject()

    return self.result
end

-- @param unit.testResult result

function _M:setTestResultObject(result)

    self.result = result
end

-- @param unit.mock.mockObject mockObject

function _M:registerMockObject(mockObject)

    tapd(self.mockObjects, mockObject)
end

-- This method is a wrapper for the ini_set() function that automatically
-- resets the modified php.ini setting to its original value after the
-- test is run.
-- @param string varName
-- @param string newValue
-- @throws Exception

function _M.__:iniSet(varName, newValue)

    if not lf.isStr(varName) then
        InvalidArgument(1, 'string')
    end
    local currentValue = ini_set(varName, newValue)
    if currentValue ~= false then
        self.iniSettings[varName] = currentValue
     else 
        lx.throw('exception', fmt('INI setting "%s" could not be set to "%s".', varName, newValue))
    end
end

-- This method is a wrapper for the setlocale() function that automatically
-- resets the locale to its original value after the test is run.
-- @param int    category
-- @param string locale
-- @throws Exception

function _M.__:setLocale()

    local args = func_get_args()
    if #args < 2 then
        lx.throw('exception')
    end
    local category = args[0]
    local locale = args[1]
    local categories = {LC_ALL, LC_COLLATE, LC_CTYPE, LC_MONETARY, LC_NUMERIC, LC_TIME}
    if defined('LC_MESSAGES') then
        tapd(categories, LC_MESSAGES)
    end
    if not tb.inList(categories, category) then
        lx.throw('exception')
    end
    if not lf.isTbl(locale) and not lf.isStr(locale) then
        lx.throw('exception')
    end
    self.locale[category] = setlocale(category, 0)
    local result = call_user_func_array('setlocale', args)
    if result == false then
        lx.throw('exception', 'The locale functionality is not implemented on your platform, ' .. 'the specified locale does not exist or the category name is ' .. 'invalid.')
    end
end

-- Returns a builder object to create mock objects using a fluent interface.
-- @param string className
-- @return unit.mock.mockBuilder

function _M:getMockBuilder(className)

    return new('unit.mock.mockBuilder', self, className)
end

-- Returns a test double for the specified class.
-- @param string originalClassName
-- @return unit.mock.mockObject

function _M:createMock(originalClassName)

    return self:getMockBuilder(originalClassName)
        :disableOriginalConstructor()
        :disableOriginalClone()
        :disableArgumentCloning()
        :disallowMockingUnknownTypes()
        :getMock()
end

function _M:mock(p1, ...)

    local mock = self:createMock(p1)
    mock.lxunitMockerize = true

    return mock
end

-- Returns a configured test double for the specified class.
-- @param string originalClassName
-- @param table  configuration
-- @return unit.mock.mockObject
-- @throws Exception

function _M.__:createConfiguredMock(originalClassName, configuration)

    local o = self:createMock(originalClassName)
    for method, ret in pairs(configuration) do
        o:method(method):willReturn(ret)
    end
    
    return o
end

-- Returns a partial test double for the specified class.
-- @param string originalClassName
-- @param table  methods
-- @return unit.mock.mockObject
-- @throws Exception

function _M.__:createPartialMock(originalClassName, methods)

    return self:getMockBuilder(originalClassName):disableOriginalConstructor():disableOriginalClone():disableArgumentCloning():disallowMockingUnknownTypes():setMethods(lf.isEmpty(methods) and nil or methods):getMock()
end

-- Returns a test proxy for the specified class.
-- @param string originalClassName
-- @param table  constructorArguments
-- @return unit.mock.mockObject
-- @throws Exception

function _M.__:createTestProxy(originalClassName, constructorArguments)

    constructorArguments = constructorArguments or {}
    
    return self:getMockBuilder(originalClassName):setConstructorArgs(constructorArguments):enableProxyingToOriginalMethods():getMock()
end

-- Mocks the specified class and returns the name of the mocked class.
-- @param string originalClassName
-- @param table  methods
-- @param table  arguments
-- @param string mockClassName
-- @param bool   callOriginalConstructor
-- @param bool   callOriginalClone
-- @param bool   callAutoload
-- @param bool   cloneArguments
-- @return string
-- @throws Exception

function _M.__:getMockClass(originalClassName, methods, arguments, mockClassName, callOriginalConstructor, callOriginalClone, callAutoload, cloneArguments)

    cloneArguments = cloneArguments or false
    callAutoload = lf.needTrue(callAutoload)
    callOriginalClone = lf.needTrue(callOriginalClone)
    callOriginalConstructor = callOriginalConstructor or false
    mockClassName = mockClassName or ''
    arguments = arguments or {}
    methods = methods or {}
    local mock = self:getMockObjectGenerator():getMock(originalClassName, methods, arguments, mockClassName, callOriginalConstructor, callOriginalClone, callAutoload, cloneArguments)
    
    return get_class(mock)
end

-- Returns a mock object for the specified abstract class with all abstract
-- methods of the class mocked. Concrete methods are not mocked by default.
-- To mock concrete methods, use the 7th parameter ($mockedMethods).
-- @param string originalClassName
-- @param table  arguments
-- @param string mockClassName
-- @param bool   callOriginalConstructor
-- @param bool   callOriginalClone
-- @param bool   callAutoload
-- @param table  mockedMethods
-- @param bool   cloneArguments
-- @return unit.mock.mockObject
-- @throws Exception

function _M.__:getMockForAbstractClass(originalClassName, arguments, mockClassName, callOriginalConstructor, callOriginalClone, callAutoload, mockedMethods, cloneArguments)

    cloneArguments = cloneArguments or false
    mockedMethods = mockedMethods or {}
    callAutoload = lf.needTrue(callAutoload)
    callOriginalClone = lf.needTrue(callOriginalClone)
    callOriginalConstructor = lf.needTrue(callOriginalConstructor)
    mockClassName = mockClassName or ''
    arguments = arguments or {}
    local mockObject = self:getMockObjectGenerator():getMockForAbstractClass(originalClassName, arguments, mockClassName, callOriginalConstructor, callOriginalClone, callAutoload, mockedMethods, cloneArguments)
    self:registerMockObject(mockObject)
    
    return mockObject
end

-- Returns a mock object for the specified trait with all abstract methods
-- of the trait mocked. Concrete methods to mock can be specified with the
-- `$mockedMethods` parameter.
-- @param string traitName
-- @param table  arguments
-- @param string mockClassName
-- @param bool   callOriginalConstructor
-- @param bool   callOriginalClone
-- @param bool   callAutoload
-- @param table  mockedMethods
-- @param bool   cloneArguments
-- @return unit.mock.mockObject
-- @throws Exception

function _M.__:getMockForTrait(traitName, arguments, mockClassName, callOriginalConstructor, callOriginalClone, callAutoload, mockedMethods, cloneArguments)

    cloneArguments = cloneArguments or false
    mockedMethods = mockedMethods or {}
    callAutoload = lf.needTrue(callAutoload)
    callOriginalClone = lf.needTrue(callOriginalClone)
    callOriginalConstructor = lf.needTrue(callOriginalConstructor)
    mockClassName = mockClassName or ''
    arguments = arguments or {}
    local mockObject = self:getMockObjectGenerator():getMockForTrait(traitName, arguments, mockClassName, callOriginalConstructor, callOriginalClone, callAutoload, mockedMethods, cloneArguments)
    self:registerMockObject(mockObject)
    
    return mockObject
end

-- Returns an object for the specified trait.
-- @param string traitName
-- @param table  arguments
-- @param string traitClassName
-- @param bool   callOriginalConstructor
-- @param bool   callOriginalClone
-- @param bool   callAutoload
-- @return object
-- @throws Exception

function _M.__:getObjectForTrait(traitName, arguments, traitClassName, callOriginalConstructor, callOriginalClone, callAutoload)

    callAutoload = lf.needTrue(callAutoload)
    callOriginalClone = lf.needTrue(callOriginalClone)
    callOriginalConstructor = lf.needTrue(callOriginalConstructor)
    traitClassName = traitClassName or ''
    arguments = arguments or {}
    
    return self:getMockObjectGenerator():getObjectForTrait(traitName, arguments, traitClassName, callOriginalConstructor, callOriginalClone, callAutoload)
end

-- @param string|null classOrInterface
-- @return \Prophecy\Prophecy\ObjectProphecy
-- @throws \LogicException

function _M.__:prophesize(classOrInterface)

    return self:getProphet():prophesize(classOrInterface)
end

-- Adds a value to the assertion counter.
-- @param int count

function _M:addToAssertionCount(count)

    self.numAssertions = self.numAssertions + count
end

-- Returns the number of assertions performed by this test.
-- @return int

function _M:getNumAssertions()

    return self.numAssertions
end

-- Returns a matcher that matches when the method is executed
-- zero or more times.
-- @return PHPUnit_Framework_MockObject_Matcher_AnyInvokedCount

function _M.s__.any()

    return new('pHPUnit_Framework_MockObject_Matcher_AnyInvokedCount')
end

-- Returns a matcher that matches when the method is never executed.
-- @return PHPUnit_Framework_MockObject_Matcher_InvokedCount

function _M.s__.never()

    return new('pHPUnit_Framework_MockObject_Matcher_InvokedCount', 0)
end

-- Returns a matcher that matches when the method is executed
-- at least N times.
-- @param int requiredInvocations
-- @return PHPUnit_Framework_MockObject_Matcher_InvokedAtLeastCount

function _M.s__.atLeast(requiredInvocations)

    return new('pHPUnit_Framework_MockObject_Matcher_InvokedAtLeastCount', requiredInvocations)
end

-- Returns a matcher that matches when the method is executed at least once.
-- @return PHPUnit_Framework_MockObject_Matcher_InvokedAtLeastOnce

function _M.s__.atLeastOnce()

    return new('pHPUnit_Framework_MockObject_Matcher_InvokedAtLeastOnce')
end

-- Returns a matcher that matches when the method is executed exactly once.
-- @return unit.mock.matcher.invokedCount

function _M:once()

    return new('unit.mock.matcher.invokedCount', 1)
end

-- Returns a matcher that matches when the method is executed
-- exactly count times.
-- @param int count
-- @return PHPUnit_Framework_MockObject_Matcher_InvokedCount

function _M.s__.exactly(count)

    return new('pHPUnit_Framework_MockObject_Matcher_InvokedCount', count)
end

-- Returns a matcher that matches when the method is executed
-- at most N times.
-- @param int allowedInvocations
-- @return PHPUnit_Framework_MockObject_Matcher_InvokedAtMostCount

function _M.s__.atMost(allowedInvocations)

    return new('pHPUnit_Framework_MockObject_Matcher_InvokedAtMostCount', allowedInvocations)
end

-- Returns a matcher that matches when the method is executed
-- at the given index.
-- @param int index
-- @return PHPUnit_Framework_MockObject_Matcher_InvokedAtIndex

function _M.s__.at(index)

    return new('pHPUnit_Framework_MockObject_Matcher_InvokedAtIndex', index)
end

-- @param mixed value
-- @return unit.mock.stub.return

function _M:returnValue(value)

    return new('unit.mock.stub.return', value)
end

-- @param table valueMap
-- @return unit.mock.stub.returnValueMap

function _M:returnValueMap(valueMap)

    return new('unit.mock.stub.returnValueMap', valueMap)
end

-- @param int argumentIndex
-- @return unit.mock.stub.returnArgument

function _M:returnArgument(argumentIndex)

    return new('unit.mock.stub.returnArgument', argumentIndex)
end

-- @param mixed callback
-- @return unit.mock.stub.returnCallback

function _M:returnCallback(callback)

    return new('unit.mock.stub.returnCallback', callback)
end

-- Returns the current object.
-- This method is useful when mocking a fluent interface.
-- @return unit.mock.stub.returnSelf

function _M:returnSelf()

    return new('unit.mock.stub.returnSelf')
end

-- @param Throwable exception
-- @return unit.mock.stub.exception

function _M:throwException(exception)

    return new('unit.mock.stub.exception', exception)
end

-- @param mixed value,  ...
-- @return PHPUnit_Framework_MockObject_Stub_ConsecutiveCalls

function _M.s__.onConsecutiveCalls()

    local args = func_get_args()
    
    return new('pHPUnit_Framework_MockObject_Stub_ConsecutiveCalls', args)
end

-- @return bool

function _M:usesDataProvider()

    return not lf.isEmpty(self.data)
end

-- @return string

function _M:dataDescription()

    return lf.isStr(self.dataName) and self.dataName or ''
end

-- Gets the data set description of a TestCase.
-- @param bool|null     includeData
-- @return string

function _M.__:getDataSetAsString(includeData)

    includeData = lf.needTrue(includeData)
    local exporter
    local buffer = ''
    if not lf.isEmpty(self.data) then
        if lf.isNum(self.dataName) then
            buffer = buffer .. fmt(' with data set #%d', self.dataName)
         else 
            buffer = buffer .. fmt(' with data set "%s"', self.dataName)
        end
        exporter = new('exporter')
        if includeData then
            buffer = buffer .. fmt(' (%s)', exporter:shortenedRecursiveExport(self.data))
        end
    end
    
    return buffer
end

-- Gets the data set of a TestCase.
-- @return table

function _M.__:getProvidedData()

    return self.data
end

-- Creates a default TestResult object.
-- @return unit.testResult

function _M.__:createResult()

    return new('unit.testResult')
end

function _M.__:handleDependencies()

    local deepCopy
    local dependency
    local clone
    local pos
    local numKeys
    local passedKeys
    local passed
    local className
    if not lf.isEmpty(self.dependencies) and not self.inIsolation then
        className = self.__cls
        passed = self.result:passed()
        passedKeys = tb.keys(passed)
        numKeys = #passedKeys
        for i = 0 + 1,numKeys + 1 do
            pos = str.strpos(passedKeys[i], ' with data set')
            if pos ~= false then
                passedKeys[i] = str.substr(passedKeys[i], 0, pos)
            end
        end
        passedKeys = tb.flip(tb.unique(passedKeys))
        for _, dependency in pairs(self.dependencies) do
            clone = false
            if str.strpos(dependency, 'clone ') == 0 then
                clone = true
                dependency = str.substr(dependency, str.len('clone '))
             elseif str.strpos(dependency, '!clone ') == 0 then
                clone = false
                dependency = str.substr(dependency, str.len('!clone '))
            end
            if str.strpos(dependency, '::') == false then
                dependency = className .. '::' .. dependency
            end
            if not passedKeys[dependency] then
                self.result:startTest(self)
                self.result:addError(self, new('skippedTestError', fmt('This test depends on "%s" to pass.', dependency)), 0)
                self.result:endTest(self, 0)
                
                return false
            end
            if passed[dependency] then
                if passed[dependency]['size'] ~= utilTest.UNKNOWN and self:getSize() ~= utilTest.UNKNOWN and passed[dependency]['size'] > self:getSize() then
                    self.result:addError(self, new('skippedTestError', 'This test depends on a test that is larger than itself.'), 0)
                    
                    return false
                end
                if clone then
                    deepCopy = new('deepCopy')
                    deepCopy:skipUncloneable(false)
                    self.dependencyInput[dependency] = deepCopy:copy(passed[dependency]['result'])
                 else 
                    self.dependencyInput[dependency] = passed[dependency]['result']
                end
             else 
                self.dependencyInput[dependency] = nil
            end
        end
    end
    
    return true
end

-- This method is called before the first test of this test class is run.

function _M.s__.setUpBeforeClass()

end

-- Sets up the fixture, for example, open a network connection.
-- This method is called before a test is executed.

function _M.__:setUp()

end

-- Performs assertions shared by all tests of a test case.
-- This method is called before the execution of a test starts
-- and after setUp() is called.

function _M.__:assertPreConditions()

end

-- Performs assertions shared by all tests of a test case.
-- This method is called before the execution of a test ends
-- and before tearDown() is called.

function _M.__:assertPostConditions()

end

-- Tears down the fixture, for example, close a network connection.
-- This method is called after a test is executed.

function _M.__:tearDown()

end

function _M:close()

end

-- This method is called after the last test of this test class is run.

function _M.s__.tearDownAfterClass()

end

-- This method is called when a test method did not execute successfully.
-- @param Throwable t
-- @throws Throwable

function _M.__:onNotSuccessfulTest(t)

    lx.throw(t)
end

-- Performs custom preparations on the process isolation template.
-- @param Text_Template template

function _M.__:prepareTemplate(template)

end

-- Get the mock object generator, creating it if it doesn't exist.
-- @return PHPUnit_Framework_MockObject_Generator

function _M.__:getMockObjectGenerator()

    if nil == self.mockObjectGenerator then
        self.mockObjectGenerator = new('pHPUnit_Framework_MockObject_Generator')
    end
    
    return self.mockObjectGenerator
end

function _M.__:startOutputBuffering()

    ob_start()
    self.outputBufferingActive = true
    self.outputBufferingLevel = ob_get_level()
end

function _M.__:stopOutputBuffering()

    if ob_get_level() ~= self.outputBufferingLevel then
        while ob_get_level() >= self.outputBufferingLevel do
            ob_end_clean()
        end
        lx.throw('riskyTestError', 'Test code or tested code did not (only) close its own output buffers')
    end
    local output = ob_get_contents()
    if self.outputCallback == false then
        self.output = output
     else 
        self.output = call_user_func_array(self.outputCallback, {output})
    end
    ob_end_clean()
    self.outputBufferingActive = false
    self.outputBufferingLevel = ob_get_level()
end

function _M.__:snapshotGlobalState()

    if self.runTestInSeparateProcess or self.inIsolation or not self.backupGlobals == true and not self.backupStaticAttributes then
        
        return
    end
    self.snapshot = self:createGlobalStateSnapshot(self.backupGlobals == true)
end

function _M.__:restoreGlobalState()

    if not self.snapshot:__is('Snapshot') then
        
        return
    end
    if self.beStrictAboutChangesToGlobalState then
        try(function()
            self:compareGlobalStateSnapshots(self.snapshot, self:createGlobalStateSnapshot(self.backupGlobals == true))
        end)
        :catch('RiskyTestError', function(rte) 
            -- Intentionally left empty
        end)
        :run()
    end
    local restorer = new('restorer')
    if self.backupGlobals == true then
        restorer:restoreGlobalVariables(self.snapshot)
    end
    if self.backupStaticAttributes then
        restorer:restoreStaticAttributes(self.snapshot)
    end
    self.snapshot = nil
    if rte then
        lx.throw(rte)
    end
end

-- @param bool backupGlobals
-- @return Snapshot

function _M.__:createGlobalStateSnapshot(backupGlobals)

    local blacklist = new('blacklist')
    for _, globalVariable in pairs(self.backupGlobalsBlacklist) do
        blacklist:addGlobalVariable(globalVariable)
    end
    if not defined('PHPUNIT_TESTSUITE') then
        blacklist:addClassNamePrefix('PHPUnit')
        blacklist:addClassNamePrefix('File_Iterator')
        blacklist:addClassNamePrefix('SebastianBergmann\\CodeCoverage')
        blacklist:addClassNamePrefix('PHP_Invoker')
        blacklist:addClassNamePrefix('PHP_Timer')
        blacklist:addClassNamePrefix('PHP_Token')
        blacklist:addClassNamePrefix('Symfony')
        blacklist:addClassNamePrefix('Text_Template')
        blacklist:addClassNamePrefix('Doctrine\\Instantiator')
        blacklist:addClassNamePrefix('Prophecy')
        for class, attributes in pairs(self.backupStaticAttributesBlacklist) do
            for _, attribute in pairs(attributes) do
                blacklist:addStaticAttribute(class, attribute)
            end
        end
    end
    
    return new('snapshot', blacklist, backupGlobals, self.backupStaticAttributes, false, false, false, false, false, false, false)
end

-- @param Snapshot before
-- @param Snapshot after
-- @throws RiskyTestError

function _M.__:compareGlobalStateSnapshots(before, after)

    local backupGlobals = self.backupGlobals == nil or self.backupGlobals == true
    if backupGlobals then
        self:compareGlobalStateSnapshotPart(before:globalVariables(), after:globalVariables(), "--- Global variables before the test\n+++ Global variables after the test\n")
        self:compareGlobalStateSnapshotPart(before:superGlobalVariables(), after:superGlobalVariables(), "--- Super-global variables before the test\n+++ Super-global variables after the test\n")
    end
    if self.backupStaticAttributes then
        self:compareGlobalStateSnapshotPart(before:staticAttributes(), after:staticAttributes(), "--- Static attributes before the test\n+++ Static attributes after the test\n")
    end
end

-- @param table  before
-- @param table  after
-- @param string header
-- @throws RiskyTestError

function _M.__:compareGlobalStateSnapshotPart(before, after, header)

    local diff
    local exporter
    local differ
    if before ~= after then
        differ = new('differ', header)
        exporter = new('exporter')
        diff = differ:diff(exporter:export(before), exporter:export(after))
        lx.throw('riskyTestError', diff)
    end
end

-- @return Prophecy\Prophet

function _M.__:getProphet()

    if self.prophet == nil then
        self.prophet = new('prophet')
    end
    
    return self.prophet
end

-- @param unit.mock.mockObject mock
-- @return bool

function _M.__:shouldInvocationMockerBeReset(mock)

    local enumerator = new('enumerator')
    for _, object in pairs(enumerator:enumerate(self.dependencyInput)) do
        if mock == object then
            
            return false
        end
    end
    if not lf.isTbl(self.testResult) and not lf.isObj(self.testResult) then
        
        return true
    end
    for _, object in pairs(enumerator:enumerate(self.testResult)) do
        if mock == object then
            
            return false
        end
    end
    
    return true
end

-- @param table testArguments
-- @param table originalTestArguments

function _M.__:registerMockObjectsFromTestArguments(testArguments, visited)

    visited = visited or {}
    local enumerator
    if self.registerMockObjectsFromTestArgumentsRecursively then
        enumerator = new('enumerator')
        for _, object in pairs(enumerator:enumerate(testArguments)) do
            if object:__is('unit.mock.mockObject') then
                self:registerMockObject(object)
            end
        end
     else 
        for _, testArgument in pairs(testArguments) do
            if testArgument:__is('unit.mock.mockObject') then
                if self:isCloneable(testArgument) then
                    testArgument = testArgument:__clone()
                end
                self:registerMockObject(testArgument)
             elseif lf.isTbl(testArgument) and not tb.inList(visited, testArgument, true) then
                tapd(visited, testArgument)
                self:registerMockObjectsFromTestArguments(testArgument, visited)
            end
        end
    end
end

function _M.__:setDoesNotPerformAssertionsFromAnnotation()

    local annotations = self:getAnnotations()
    if annotations['method']['doesNotPerformAssertions'] then
        self.doesNotPerformAssertions = true
    end
end

-- @param unit.mock.mockObject testArgument
-- @return bool

function _M.__:isCloneable(testArgument)

    local reflector = new('reflectionObject', testArgument)
    if not reflector:isCloneable() then
        
        return false
    end
    if reflector:hasMethod('__clone') and reflector:getMethod('__clone'):isPublic() then
        
        return true
    end
    
    return false
end

return _M

