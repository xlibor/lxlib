
local lx, _M, mt = oo{
    _cls_       = '',
    _bond_      = 'unit.testListener',
    _static_    = {}
}

local app, lf, tb, str, new = lx.kit()

function _M:new()

    local this = {
        column = 0,
        maxColumn = nil,
        lastTestFailed = false,
        numAssertions = 0,
        numTests = -1,
        numTestsRun = 0,
        numTestsWidth = nil,
        colors = false,
        debug = false,
        verbose = false,
        numberOfColumns = nil,
        reverse = false,
        defectListPrinted = false
    }
    
    return oo(this, mt)
end

-- @param command           cmd
-- @param bool|null         verbose
-- @param string|null       colors
-- @param bool|null         debug
-- @param int|string|null   numberOfColumns
-- @param bool|null         reverse

function _M:ctor(cmd, verbose, debug, numberOfColumns, reverse)

    reverse = reverse or false
    numberOfColumns = numberOfColumns or 80
    debug = debug or false
    verbose = verbose or false

    self.cmd = cmd
    self.numberOfColumns = numberOfColumns
    self.verbose = verbose
    self.debug = debug
    self.reverse = reverse

end

function _M:write(s)

    self.cmd:print(s)

end

-- @param unit.testResult result

function _M:printResult(result)

    self:printHeader()
    self:printErrors(result)
    self:printWarnings(result)
    self:printFailures(result)
    if self.verbose then
        self:printRisky(result)
        self:printIncompletes(result)
        self:printSkipped(result)
    end
    self:printFooter(result)
end

-- @param table  defects
-- @param string type

function _M.__:printDefects(defects, type)

    local count = #defects
    if count == 0 then
        
        return
    end
    if self.defectListPrinted then
        self:write("\n--\n\n")
    end
    self:write(fmt("There %s %d %s%s:\n", count == 1 and 'was' or 'were', count, type, count == 1 and '' or 's'))
    local i = 1
    if self.reverse then
        defects = tb.reverse(defects)
    end
    for _, defect in pairs(defects) do
        self:printDefect(defect, i)
        i = i + 1
    end
    self.defectListPrinted = true
end

-- @param unit.testFailure defect
-- @param int                           count

function _M.__:printDefect(defect, count)

    self:printDefectHeader(defect, count)
    self:printDefectTrace(defect)
end

-- @param unit.testFailure          defect
-- @param int                       count

function _M.__:printDefectHeader(defect, count)

    self:write(
        fmt("\n%d) %s: %s\n",
            count, defect:getTestName(), defect:getLine()
        )
    )
end

-- @param unit.testFailure defect

function _M.__:printDefectTrace(defect)

    local e = defect:thrownException()
    self:write(e:toStr())
    e = e:getPrevious()
    while e do
        self:write("\nCaused by\n" .. e:toStr())
        e = e:getPrevious()
    end
end

-- @param unit.testResult result

function _M.__:printErrors(result)

    self:printDefects(result:errors(), 'error')
end

-- @param unit.testResult result

function _M.__:printFailures(result)

    self:printDefects(result:failures(), 'failure')
end

-- @param unit.testResult result

function _M.__:printWarnings(result)

    self:printDefects(result:warnings(), 'warning')
end

-- @param unit.testResult result

function _M.__:printIncompletes(result)

    self:printDefects(result:notImplemented(), 'incomplete test')
end

-- @param unit.testResult result

function _M.__:printRisky(result)

    self:printDefects(result:risky(), 'risky test')
end

-- @param unit.testResult result

function _M.__:printSkipped(result)

    self:printDefects(result:skipped(), 'skipped test')
end

function _M.__:printHeader()

    local timing = app:get('app.timing')
    local cost = timing:past()

    self:write(fmt(
        "\n\n" .. 'time:%.3f second, memory:2 M' .. "\n\n",
        cost)
    )
end

-- @param unit.testResult result

function _M.__:printFooter(result)

    if result:count() == 0 then
        self.cmd:warn('No tests executed!')
        
        return
    end
    if result:wasSuccessful() and result:allHarmless() and result:allCompletelyImplemented() and result:noneSkipped() then
        self.cmd:cheer(fmt('OK (%d test%s, %d assertion%s)', result:count(), result:count() == 1 and '' or 's', self.numAssertions, self.numAssertions == 1 and '' or 's'))
    else
        if result:wasSuccessful() then
            if self.verbose then
                self:write("\n")
            end
            self.cmd:warn('OK, but incomplete, skipped, or risky tests!')
        else
            self:write("\n")
            if result:errorCount() then
                self.cmd:error('ERRORS!')
            elseif result:failureCount() then
                self.cmd:error('FAILURES!')
            elseif result:warningCount() then
                self.cmd:warn('WARNINGS!')
            end
        end

        self:writeCountString(result:count(), 'Tests', 'info', true)
        self:writeCountString(self.numAssertions, 'Assertions', 'info', true)
        self:writeCountString(result:errorCount(), 'Errors', 'error')
        self:writeCountString(result:failureCount(), 'Failures', 'error')
        self:writeCountString(result:warningCount(), 'Warnings', 'warn')
        self:writeCountString(result:skippedCount(), 'Skipped', 'warn')
        self:writeCountString(result:notImplementedCount(), 'Incomplete', 'warn')
        self:writeCountString(result:riskyCount(), 'Risky', 'warn')

    end
end

function _M:printWaitPrompt()

    self:write("\n<RETURN> to continue\n")
end

-- An error occurred.
-- @param unit.test test
-- @param exception              e
-- @param float                  time

function _M:addError(test, e, time)

    self:writeProgressWithColor('error', 'E')
    self.lastTestFailed = true
end

-- A failure occurred.
-- @param unit.test                     test
-- @param unit.assertionFailedError     e
-- @param float                         time

function _M:addFailure(test, e, time)

    self:writeProgressWithColor('error', 'F')
    self.lastTestFailed = true
end

-- A warning occurred.
-- @param unit.test         test
-- @param unit.warning      e
-- @param float             time

function _M:addWarning(test, e, time)

    self:writeProgressWithColor('warn', 'W')
    self.lastTestFailed = true
end

-- Incomplete test.
-- @param unit.test             test
-- @param exception             e
-- @param float                 time

function _M:addIncompleteTest(test, e, time)

    self:writeProgressWithColor('warn', 'I')
    self.lastTestFailed = true
end

-- Risky test.
-- @param unit.test             test
-- @param exception             e
-- @param float                 time

function _M:addRiskyTest(test, e, time)

    self:writeProgressWithColor('warn', 'R')
    self.lastTestFailed = true
end

-- Skipped test.
-- @param unit.test             test
-- @param exception             e
-- @param float                 time

function _M:addSkippedTest(test, e, time)

    self:writeProgressWithColor('question', 'S')
    self.lastTestFailed = true
end

-- A testsuite started.
-- @param unit.testSuite suite

function _M:startTestSuite(suite)

    if self.numTests == -1 then
        self.numTests = suite:count()
        self.numTestsWidth = str.len(tostring(self.numTests))
        self.maxColumn = self.numberOfColumns - str.len('  /  (XXX%)') - 2 * self.numTestsWidth
    end
end

-- A testsuite ended.
-- @param unit.testSuite suite

function _M:endTestSuite(suite)

end

-- A test started.
-- @param unit.test test

function _M:startTest(test)

    if self.debug then
        self:write(fmt("\nStarting test '%s'.\n", PHPUnit_Util_Test.describe(test)))
    end
end

-- A test ended.
-- @param unit.test         test
-- @param float             time

function _M:endTest(test, time)

    if not self.lastTestFailed then
        self:writeProgress('.')
    end
    if test:__is('unit.testCase') then
        self.numAssertions = self.numAssertions + test:getNumAssertions()
    end
    self.lastTestFailed = false
    if test:__is('unit.testCase') then
        if not test:hasExpectationOnOutput() then
            self:write(test:getActualOutput())
        end
    end
end

-- @param string progress

function _M.__:writeProgress(progress)

    self:write(progress)
    self.column = self.column + 1
    self.numTestsRun = self.numTestsRun + 1
    if self.column == self.maxColumn or self.numTestsRun == self.numTests then
        if self.numTestsRun == self.numTests then
            self:write(str_repeat(' ', self.maxColumn - self.column))
        end
        self:write(fmt(' %' .. self.numTestsWidth .. 'd / %' .. self.numTestsWidth .. 'd (%3s%%)', self.numTestsRun, self.numTests, floor(self.numTestsRun / self.numTests * 100)))
        if self.column == self.maxColumn then
            self:writeNewLine()
        end
    end
end

function _M.__:writeNewLine()

    self.column = 0
    self:write("\n")
end

-- Formats a buffer with a specified ANSI color sequence if colors are
-- enabled.
-- @param string color
-- @param string buffer
-- @return string

function _M.__:formatWithColor(color, buffer)

    if not self.colors then
        
        return buffer
    end
    local codes = tb.map(str.split(color, ','), 'trim')
    local lines = str.split(buffer, "\n")
    local padding = max(tb.map(lines, 'strlen'))
    local styles = {}
    for _, code in pairs(codes) do
        tapd(styles, self.ansiCodes[code])
    end
    local style = fmt("\33[%sm", str.join(styles, ';'))
    local styledLines = {}
    for _, line in pairs(lines) do
        tapd(styledLines, style .. str_pad(line, padding) .. "\33[0m")
    end
    
    return str.join(styledLines, "\n")
end

-- Writes a buffer out with a color sequence if colors are enabled.
-- @param string        color
-- @param string        buffer
-- @param bool|null     lineBreak

function _M.__:writeWithColor(color, buffer, lineBreak)

    lineBreak = lf.needTrue(lineBreak)
    self:write(self:formatWithColor(color, buffer))
    if lineBreak then
        self:write("\n")
    end
end

-- Writes progress with a color sequence if colors are enabled.
-- @param string color
-- @param string buffer

function _M.__:writeProgressWithColor(style, buffer)

    local s = '<' .. style .. '>' .. buffer .. '</' .. style .. '>'
    self.cmd:print(s)

    -- buffer = self:formatWithColor(color, buffer)
    -- self:writeProgress(buffer)
end

-- @param int           count
-- @param string        name
-- @param string        color
-- @param bool|null     always

function _M.__:writeCountString(count, name, style, always)

    always = always or false
    local first = true
    if always or count > 0 then
        lf.call({self.cmd, style}, fmt('%s%s: %d', not first and ', ' or '', name, count))
        first = false
    end
end

return _M

