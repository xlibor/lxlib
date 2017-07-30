
local lx, _M, mt = oo{
    _cls_       = ''
}

local app, lf, tb, str, new = lx.kit()
local try = lx.try

local Assert = lx.use('unit.assert')

function _M:new()

    local this = {
        _passed = {},
        _errors = {},
        _failures = {},
        _warnings = {},
        _notImplemented = {},
        _risky = {},
        _skipped = {},
        listeners = {},
        runTests = 0,
        _time = 0,
        _topTestSuite = nil,
        codeCoverage = nil,
        convertErrorsToExceptions = true,
        _stop = false,
        _stopOnError = false,
        _stopOnFailure = false,
        _stopOnWarning = false,
        _stopOnRisky = false,
        _stopOnIncomplete = false,
        _stopOnSkipped = false,
        beStrictAboutTestsThatDoNotTestAnything = false,
        beStrictAboutOutputDuringTests = false,
        beStrictAboutTodoAnnotatedTests = false,
        beStrictAboutResourceUsageDuringSmallTests = false,
        _enforceTimeLimit = false,
        timeoutForSmallTests = 1,
        timeoutForMediumTests = 10,
        timeoutForLargeTests = 60,
        lastTestFailed = false,
        registerMockObjectsFromTestArgumentsRecursively = false
    }

    return oo(this, mt)
end

-- @param unit.test test

function _M:run(test)

    local error = false
    local failure = false
    local warning = false
    local incomplete = false
    local risky = false
    local skipped = false

    Assert.resetCount()

    self:startTest(test)

    local timeBegin = lf.now(true)
    local time
    local excp

    try(function()
        test:runBare()
    end)
    :catch('unit.assertionFailedError', function(e)
        failure = true
        if e:__is('unit.riskyTestError') then
            risky = true
        elseif e:__is('unit.incompleteTestError') then
            incomplete = true
        elseif e:__is('unit.skippedTestError') then
            skipped = true
        end
        excp = e
    end)
    :catch('unit.warning', function(e)
        warning = true
        excp = e
    end)
    :catch('unit.exception', function(e)
        error = true
        excp = e
    end)
    :catch('exception', function(e)
        error = true
        excp = e
    end)
    :run()

    time = lf.now(true) - timeBegin

    test:addToAssertionCount(Assert.getCount())

    if error then
        self:addError(test, excp, time)
    elseif failure then
        self:addFailure(test, excp, time)
    elseif warning then
        self:addWarning(test, excp, time)
    end

    self:endTest(test, time)
end

function _M:fireEvent(event, ...)

    for _, listener in pairs(self.listeners) do
        local action = listener[event]
        action(listener, ...)
    end
end

-- Informs the result that a test will be started.
-- @param unit.test     test

function _M:startTest(test)

    self.lastTestFailed = false
    self.runTests = self.runTests + test:count()

    self:fireEvent('startTest', test)
end

-- Informs the result that a test was completed.
-- @param unit.test          test
-- @param number             time

function _M:endTest(test, time)

    self:fireEvent('endTest', test, time)

    local key, class

    if (not self.lastTestFailed) and test:__is('unit.testCase') then
        class = test.__cls
        key = class .. '.' .. test:getName()
        self._passed[key] = {result = test:getResult(), size = 0}
        self._time = self._time + time
    end
end

-- Gets the number of run tests.
-- @return int

function _M:count()

    return self.runTests
end

-- Checks whether the test run should stop.
-- @return bool

function _M:shouldStop()

    return self._stop
end

-- Marks that the test run should stop.

function _M:stop()

    self._stop = true
end

-- Returns the code coverage object.
-- @return CodeCoverage

function _M:getCodeCoverage()

    return self.codeCoverage
end

-- Sets the code coverage object.
-- @param CodeCoverage codeCoverage

function _M:setCodeCoverage(codeCoverage)

    self.codeCoverage = codeCoverage
end

-- Enables or disables the error-to-exception conversion.
-- @param bool flag

function _M:convertErrorsToExceptions(flag)

    self.convertErrorsToExceptions = flag
end

-- Returns the error-to-exception conversion setting.
-- @return bool

function _M:getConvertErrorsToExceptions()

    return self.convertErrorsToExceptions
end

-- Enables or disables the stopping when an error occurs.
-- @param bool flag

function _M:stopOnError(flag)

    self._stopOnError = flag
end

-- Enables or disables the stopping when a failure occurs.
-- @param bool flag

function _M:stopOnFailure(flag)

    self._stopOnFailure = flag
end

-- Enables or disables the stopping when a warning occurs.
-- @param bool flag

function _M:stopOnWarning(flag)

    self._stopOnWarning = flag
end

-- @param bool flag

function _M:enforceTimeLimit(flag)

    self._enforceTimeLimit = flag
end

-- @return bool

function _M:enforcesTimeLimit()

    return self._enforceTimeLimit
end

-- Enables or disables the stopping for risky tests.
-- @param bool flag

function _M:stopOnRisky(flag)

    self._stopOnRisky = flag
end

-- Enables or disables the stopping for incomplete tests.
-- @param bool flag

function _M:stopOnIncomplete(flag)

    self._stopOnIncomplete = flag
end

-- Enables or disables the stopping for skipped tests.
-- @param bool flag

function _M:stopOnSkipped(flag)

    self._stopOnSkipped = flag
end

-- Returns the time spent running the tests.
-- @return float

function _M:time()

    return self._time
end

-- Returns whether the entire test was successful or not.
-- @return bool

function _M:wasSuccessful()

    return lf.isEmpty(self._errors) and lf.isEmpty(self._failures) and lf.isEmpty(self._warnings)
end

-- Adds an error to the list of errors.
-- @param unit.test             test
-- @param throwable             t
-- @param float                 time

function _M:addError(test, t, time)

    local notifyMethod
    if t:__is('unit.riskyTest') then
        tapd(self._risky, new('unit.testFailure', test, t))
        notifyMethod = 'addRiskyTest'
        if self._stopOnRisky then
            self:stop()
        end
    elseif t:__is('unit.incompleteTest') then
        tapd(self._notImplemented, new('unit.testFailure', test, t))
        notifyMethod = 'addIncompleteTest'
        if self._stopOnIncomplete then
            self:stop()
        end
    elseif t:__is('unit.skippedTest') then
        tapd(self._skipped, new('unit.testFailure', test, t))
        notifyMethod = 'addSkippedTest'
        if self._stopOnSkipped then
            self:stop()
        end
    else
        tapd(self._errors, new('unit.testFailure', test, t))
        notifyMethod = 'addError'
        if self._stopOnError or self._stopOnFailure then
            self:stop()
        end
    end

    if t:__is('errorException') then
        t = new('unit.exceptionWrapper', t)
    end

    self:fireEvent(notifyMethod, test, t, time)

    self.lastTestFailed = true
    self._time = self._time + time
end

-- Adds a warning to the list of warnings.
-- The passed in exception caused the warning.
-- @param unit.test         test
-- @param unit.warning      e
-- @param float             time

function _M:addWarning(test, e, time)

    if self._stopOnWarning then
        self:stop()
    end
    tapd(self._warnings, new('unit.testFailure', test, e))

    self:fireEvent('addWarning', test, e, time)

    self._time = self._time + time
end

-- Adds a failure to the list of failures.
-- The passed in exception caused the failure.
-- @param unit.test                     test
-- @param unit.assertionFailedError     e
-- @param float                         time

function _M:addFailure(test, e, time)

    local notifyMethod
    if e:__is('unit.riskyTest') or e:__is('unit.outputError') then
        tapd(self._risky, new('unit.testFailure', test, e))
        notifyMethod = 'addRiskyTest'
        if self._stopOnRisky then
            self:stop()
        end
    elseif e:__is('unit.incompleteTest') then
        tapd(self._notImplemented, new('unit.testFailure', test, e))
        notifyMethod = 'addIncompleteTest'
        if self._stopOnIncomplete then
            self:stop()
        end
    elseif e:__is('unit.skippedTest') then
        tapd(self._skipped, new('unit.testFailure', test, e))
        notifyMethod = 'addSkippedTest'
        if self._stopOnSkipped then
            self:stop()
        end
    else
        tapd(self._failures, new('unit.testFailure', test, e))
        notifyMethod = 'addFailure'
        if self._stopOnFailure then
            self:stop()
        end
    end

    self:fireEvent('addFailure', test, e, time)

    self.lastTestFailed = true
    self._time = self._time + time
end

-- Informs the result that a testsuite will be started.
-- @param unit.testSuite suite

function _M:startTestSuite(suite)

    if not self._topTestSuite then
        self._topTestSuite = suite
    end

    self:fireEvent('startTestSuite', suite)
end

-- Informs the result that a testsuite was completed.
-- @param unit.testSuite suite

function _M:endTestSuite(suite)
    
    self:fireEvent('endTestSuite', suite)
end

-- Returns true if no risky test occurred.
-- @return bool

function _M:allHarmless()

    return self:riskyCount() == 0
end

-- Gets the number of risky tests.
-- @return int
-- @since Method available since Release 4.0.0

function _M:riskyCount()

    return #self._risky
end

-- Returns true if no incomplete test occurred.
-- @return bool

function _M:allCompletelyImplemented()

    return self:notImplementedCount() == 0
end

-- Gets the number of incomplete tests.
-- @return int

function _M:notImplementedCount()

    return #self._notImplemented
end

-- Returns an Enumeration for the risky tests.
-- @return table
-- @since Method available since Release 4.0.0

function _M:risky()

    return self._risky
end

-- Returns an Enumeration for the incomplete tests.
-- @return table

function _M:notImplemented()

    return self._notImplemented
end

-- Returns true if no test has been skipped.
-- @return bool
-- @since Method available since Release 3.0.0

function _M:noneSkipped()

    return self:skippedCount() == 0
end

-- Gets the number of skipped tests.
-- @return int
-- @since Method available since Release 3.0.0

function _M:skippedCount()

    return #self._skipped
end

-- Returns an Enumeration for the skipped tests.
-- @return table
-- @since Method available since Release 3.0.0

function _M:skipped()

    return self._skipped
end

-- Gets the number of detected errors.
-- @return int

function _M:errorCount()

    return #self._errors
end

-- Returns an Enumeration for the errors.
-- @return table

function _M:errors()

    return self._errors
end

-- Gets the number of detected failures.
-- @return int

function _M:failureCount()

    return #self._failures
end

-- Returns an Enumeration for the failures.
-- @return table

function _M:failures()

    return self._failures
end

-- Gets the number of detected warnings.
-- @return int
-- @since Method available since Release 5.1.0

function _M:warningCount()

    return #self._warnings
end

-- Returns an Enumeration for the warnings.
-- @return table
-- @since Method available since Release 5.1.0

function _M:warnings()

    return self._warnings
end

-- Returns the names of the tests that have passed.
-- @return table
-- @since Method available since Release 3.4.0

function _M:passed()

    return self._passed
end

-- Returns the (top) test suite.
-- @return unit.testSuite
-- @since Method available since Release 3.0.0

function _M:topTestSuite()

    return self._topTestSuite
end

-- Registers a TestListener.
-- @param unit.testListener listener

function _M:addListener(listener)

    tapd(self.listeners, listener)
end

-- Unregisters a TestListener.
-- @param unit.testListener listener

function _M:removeListener(listener)

    for key, _listener in pairs(self.listeners) do
        if listener == _listener then
            self.listeners[key] = nil
        end
    end
end

-- Flushes all flushable TestListeners.

function _M:flushListeners()

    for _, listener in pairs(self.listeners) do
        if listener:__is('unit.resultPrinter') then
            listener:flush()
        end
    end
end

return _M

