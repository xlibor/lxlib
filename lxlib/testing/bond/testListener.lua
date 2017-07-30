
local __ = {
    _cls_ = ''
}
-- An error occurred.
-- @param unit.test test
-- @param Exception              e
-- @param float                  time

function __:addError(test, e, time) end

-- A warning occurred.
-- @param unit.test         test
-- @param unit.warning      e
-- @param float             time

-- public function addWarning(unit.test test, unit.warning e, time);
-- A failure occurred.
-- @param unit.test                     test
-- @param unit.assertionFailedError     e
-- @param float                         time

function __:addFailure(test, e, time) end

-- Incomplete test.
-- @param unit.test         test
-- @param exception         e
-- @param float             time

function __:addIncompleteTest(test, e, time) end

-- Risky test.
-- @param unit.test         test
-- @param exception         e
-- @param float             time

function __:addRiskyTest(test, e, time) end

-- Skipped test.
-- @param unit.test         test
-- @param exception         e
-- @param float             time

function __:addSkippedTest(test, e, time) end

-- A test suite started.
-- @param unit.testSuite    suite

function __:startTestSuite(suite) end

-- A test suite ended.
-- @param unit.testSuite    suite

function __:endTestSuite(suite) end

-- A test started.
-- @param unit.test         test

function __:startTest(test) end

-- A test ended.
-- @param unit.test         test
-- @param float             time

function __:endTest(test, time) end

return __

