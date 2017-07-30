
local lx, _M, mt = oo{
    _cls_       = ''
}

local app, lf, tb, str, new = lx.kit()
local try, throw = lx.try, lx.throw

function _M:new()

    local this = {
        exporter = new('unit.exporter')
    }

    return oo(this, mt)
end

function _M:ctor()

    self.handlers = self:regHandler()
end

function _M:regHandler()

    local handlers = {
        'Type', 'Scalar', 'Number', 'Table', 'Object',
        'MockObject', 'Datetime'
    }

    handlers = tb.reverse(handlers)

    return handlers
end

-- Asserts that two values are equal.
-- @param mixed|null    expected     First value to compare
-- @param mixed|null    actual       Second value to compare
-- @param float         delta        Allowed numerical distance between two values to consider them equal
-- @param bool          canonicalize Arrays are sorted before comparison when set to true
-- @param bool          ignoreCase   Case is ignored when set to true

function _M:assertEquals(expected, actual, delta, canonicalize, ignoreCase)

    local handler, accept
    for _, v in ipairs(self.handlers) do
        accept = 'accepts' .. v

        if self[accept](self, expected, actual) then
            handler = v
            break
        end
    end

    if not handler then

    end

    local assertHandler = self['assert' .. handler]
    assertHandler(self, expected, actual, delta, canonicalize, ignoreCase)
end

-- Returns whether the comparator can compare two values.
-- @param  mixed        expected The first value to compare
-- @param  mixed|null   actual   The second value to compare
-- @return bool

function _M:acceptsScalar(expected, actual)

    local ret

    return (lf.isScalar(expected) and lf.isScalar(actual))
        or 
        (lf.isStr(expected) and (lf.isObj(actual) and actual:__is('strable')))
        or 
        ((lf.isObj(expected) and expected:__is('strable')) and lf.isStr(actual))
end

function _M:acceptsTable(expected, actual)

    return lf.isTbl(expected) and lf.isTbl(actual)
end

function _M:acceptsObject(expected, actual)

    return lf.isObj(expected) and lf.isObj(actual)
end

function _M:acceptsDatetime(expected, actual)

    if lf.isObj(expected) and lf.isObj(actual) then
        return expected:__is('datetime') or actual:__is('datetime')
    else
        return false
    end
end

function _M:acceptsNumber(expected, actual)

    return lf.isNum(expected) and lf.isNum(actual)
end

function _M:acceptsType(expected, actual)

    return true
end

function _M:acceptsMockObject(expected, actual)

    if lf.isObj(expected) and lf.isObj(actual) then
        return expected:__is('unit.mock.mockObject') and actual:__is('unit.mock.mockObject')
    else
        return false
    end
end

function _M:assertScalar(expected, actual, delta, canonicalize, ignoreCase)

    ignoreCase = ignoreCase or false
    canonicalize = canonicalize or false
    delta = delta or 0.0
    local expectedToCompare = expected
    local actualToCompare = actual
    -- always compare as strings to avoid strange behaviour
    -- otherwise 0 == 'Foobar'
    if lf.isStr(expected) or lf.isStr(actual) then
        expectedToCompare = tostring(expectedToCompare)
        actualToCompare = tostring(actualToCompare)
        if ignoreCase then
            expectedToCompare = str.lower(expectedToCompare)
            actualToCompare = str.lower(actualToCompare)
        end
    end
    if expectedToCompare ~= actualToCompare then
        if lf.isStr(expected) and lf.isStr(actual) then
            lx.throw('unit.comparisonFailure', expected, actual, self.exporter:export(expected), self.exporter:export(actual), false, 'Failed asserting that two strings are equal.')
        end
        lx.throw('unit.comparisonFailure', expected, actual, '', '', false, fmt('Failed asserting that %s matches expected %s.', self.exporter:export(actual), self.exporter:export(expected)))
    end

end

function _M:assertType(expected, actual, delta, canonicalize, ignoreCase)

    ignoreCase = ignoreCase or false
    canonicalize = canonicalize or false
    delta = delta or 0.0
    if type(expected) ~= type(actual) then
        lx.throw('unit.comparisonFailure', expected, actual, '', '', false, fmt('%s does not match expected type "%s".', self.exporter:shortenedExport(actual), type(expected)))
    end
end

function _M:assertTable(expected, actual, delta, canonicalize, ignoreCase)

    ignoreCase = ignoreCase or false
    canonicalize = canonicalize or false
    delta = delta or 0.0
    if canonicalize then
        table.sort(expected)
        table.sort(actual)
    end
    local remaining = tb.clone(actual)
    local actString = "Array (\n"
    local expString = actString
    local equal = true

    for key, value in pairs(expected) do
        remaining[key] = nil
        if not tb.has(actual, key) then
            expString = expString .. fmt("    %s => %s\n", self.exporter:export(key), self.exporter:shortenedExport(value))
            equal = false
        else
            try(function()
                self:assertEquals(value, actual[key], delta, canonicalize, ignoreCase, processed)
                expString = expString .. fmt("    %s => %s\n", self.exporter:export(key), self.exporter:shortenedExport(value))
                actString = actString .. fmt("    %s => %s\n", self.exporter:export(key), self.exporter:shortenedExport(actual[key]))
            end)
            :catch('unit.comparisonFailure', function(e)
                expString = expString .. fmt("    %s => %s\n", self.exporter:export(key), e:getExpectedAsString() and self:indent(e:getExpectedAsString()) or self.exporter:shortenedExport(e:getExpected()))
                actString = actString .. fmt("    %s => %s\n", self.exporter:export(key), e:getActualAsString() and self:indent(e:getActualAsString()) or self.exporter:shortenedExport(e:getActual()))
                equal = false
            end)
            :run()
        end
    end

    for key, value in pairs(remaining) do
        actString = actString .. fmt("    %s => %s\n", self.exporter:export(key), self.exporter:shortenedExport(value))
        equal = false
    end
    expString = expString .. ')'
    actString = actString .. ')'
    if not equal then
        lx.throw('unit.comparisonFailure',
            expected, actual, expString, actString, false,
            'Failed asserting that two arrays are equal.'
        )
    end
end

function _M:assertObject(expected, actual, delta, canonicalize, ignoreCase)

    processed = processed or {}
    ignoreCase = ignoreCase or false
    canonicalize = canonicalize or false
    delta = delta or 0.0
    if actual.__cls ~= expected.__cls then
        lx.throw('unit.comparisonFailure', expected, actual,
            self.exporter:export(expected),
            self.exporter:export(actual), false,
            fmt('%s is not instance of expected class "%s".',
                self.exporter:export(actual),
                expected.__cls
            )
        )
    end
    -- don't compare twice to allow for cyclic dependencies
    if tb.inList(processed, {actual, expected}, true) or tb.inList(processed, {expected, actual}, true) then
        
        return
    end
    tapd(processed, {actual, expected})
    -- don't compare objects if they are identical
    -- this helps to avoid the error "maximum function nesting level reached"
    -- CAUTION: this conditional clause is not tested
    if actual ~= expected then
        try(function()
            parent.assertEquals(self:toArray(expected), self:toArray(actual), delta, canonicalize, ignoreCase, processed)
        end)
        :catch('unit.comparisonFailure', function(e) 
            lx.throw('unit.comparisonFailure', expected, actual, substr_replace(e:getExpectedAsString(), expected.__cls .. ' Object', 0, 5), substr_replace(e:getActualAsString(), get_class(actual) .. ' Object', 0, 5), false, 'Failed asserting that two objects are equal.')
        end)
        :run()
    end
end

function _M:assertDatetime(expected, actual, delta, canonicalize, ignoreCase)

    processed = processed or {}
    ignoreCase = ignoreCase or false
    canonicalize = canonicalize or false
    delta = delta or 0.0
    delta = new('dateInterval', fmt('PT%sS', math.abs(delta)))
    local expectedLower = expected:__clone()
    local expectedUpper = expected:__clone()
    if actual < expectedLower:sub(delta) or actual > expectedUpper:add(delta) then
        lx.throw('unit.comparisonFailure', expected, actual, self:dateTimeToString(expected), self:dateTimeToString(actual), false, 'Failed asserting that two DateTime objects are equal.')
    end
end

function _M:assertNumber(expected, actual, delta, canonicalize, ignoreCase)

    ignoreCase = ignoreCase or false
    canonicalize = canonicalize or false
    delta = delta or 0.0

    if math.abs(actual - expected) > delta then

        lx.throw('unit.comparisonFailure',
            expected, actual, '', '', false,
            fmt('Failed asserting that %s matches expected %s.',
                self.exporter:export(actual),
                self.exporter:export(expected)
            )
        )
    end
end

_M.assertMockObject = _M.assertObject

function _M.__:indent(lines)

    return str.trim(str.replace(lines, "\n", "\n    "))
end

function _M.__:toArray(object)

    return self.exporter:toArray(object)
end

function _M.__:dateTimeToString(datetime)

    local string = datetime:format('Y-m-d\\TH:i:s.uO')
    
    return string and string or 'Invalid DateTimeInterface object'
end

return _M

