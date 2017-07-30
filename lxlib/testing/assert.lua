
local lx, _M = oo{
    _cls_       = '',
    _static_    = {
        count   = 0,
    }
}

local app, lf, tb, str, new = lx.kit()
local fs = lx.fs

local InvalidArgument = lx.use('unit.invalidArgumentHelper').factory

local static

function _M._init_(this)

    static = this.static
end

-- Asserts that an table has a specified key.
-- @param string                exception
-- @param function              callback
-- @param string|null           message

function _M:assertException(exception, callback, message)

    message = message or ''
    local caught
    lx.try(callback)
    :catch(function(e)
        caught = e
    end)
    :run()

    local constraint = new('unit.constraint.exception', exception)
    self:assertThat(caught, constraint, message)
end

function _M:assertArrayHasKey(key, array, message)

    message = message or ''
    if not (lf.isNum(key) or lf.isStr(key)) then
        InvalidArgument(1, 'integer or string')
    end
    if not lf.isTbl(array) then
        InvalidArgument(2, 'table')
    end
    local constraint = new('unit.constraint.arrayHasKey', key)
    self:assertThat(array, constraint, message)
end

-- Asserts that an table has a specified subset.
-- @param table|ArrayAccess subset
-- @param table|ArrayAccess table
-- @param bool              strict  Check for object identity
-- @param string            message

function _M:assertArraySubset(subset, array, strict, message)

    message = message or ''
    strict = strict or false
    if not (lf.isTbl(subset) or subset:__is('ArrayAccess')) then
        InvalidArgument(1, 'array or ArrayAccess')
    end
    if not (lf.isTbl(array) or array:__is('ArrayAccess')) then
        InvalidArgument(2, 'array or ArrayAccess')
    end
    local constraint = new('unit.constraint.arraySubset', subset, strict)
    self:assertThat(array, constraint, message)
end

-- Asserts that an table does not have a specified key.
-- @param mixed                 key
-- @param table                 table
-- @param string|null           message

function _M:assertArrayNotHasKey(key, array, message)

    message = message or ''
    if not (lf.isNum(key) or lf.isStr(key)) then
        InvalidArgument(1, 'integer or string')
    end
    if not lf.isTbl(array) then
        InvalidArgument(2, 'table')
    end
    local constraint = new(
        'unit.constraint.logicalNot',
        new('unit.constraint.arrayHasKey', key)
    )
    self:assertThat(array, constraint, message)
end

-- Asserts that a haystack contains a needle.
-- @param mixed         needle
-- @param mixed         haystack
-- @param string|null   message
-- @param bool|null     ignoreCase
-- @param bool|null     checkForObjectIdentity
-- @param bool|null     checkForNonObjectIdentity

function _M:assertContains(needle, haystack, message, ignoreCase, checkForObjectIdentity, checkForNonObjectIdentity)

    checkForNonObjectIdentity = checkForNonObjectIdentity or false
    checkForObjectIdentity = lf.needTrue(checkForObjectIdentity)
    ignoreCase = ignoreCase or false
    message = message or ''
    local constraint
    if lf.isTbl(haystack) or
        (lf.isObj(haystack) and haystack:__is('eachable')) then

        constraint = new('unit.constraint.eachableContains', needle, checkForObjectIdentity, checkForNonObjectIdentity)
    elseif lf.isStr(haystack) then
        if not lf.isStr(needle) then
            InvalidArgument(1, 'string')
        end
        constraint = new('unit.constraint.stringContains', needle, ignoreCase)
    else 
        InvalidArgument(2, 'array, eachable or string')
    end
    self:assertThat(haystack, constraint, message)
end

-- Asserts that a haystack that is stored in a static attribute of a class
-- or an attribute of an object contains a needle.
-- @param mixed         needle
-- @param string        haystackAttributeName
-- @param string|object haystackClassOrObject
-- @param string        message
-- @param bool          ignoreCase
-- @param bool          checkForObjectIdentity
-- @param bool          checkForNonObjectIdentity

function _M:assertAttributeContains(needle, haystackAttributeName, haystackClassOrObject, message, ignoreCase, checkForObjectIdentity, checkForNonObjectIdentity)

    checkForNonObjectIdentity = checkForNonObjectIdentity or false
    checkForObjectIdentity = lf.needTrue(checkForObjectIdentity)
    ignoreCase = ignoreCase or false
    message = message or ''
    self:assertContains(needle, self:readAttribute(haystackClassOrObject, haystackAttributeName), message, ignoreCase, checkForObjectIdentity, checkForNonObjectIdentity)
end

-- Asserts that a haystack does not contain a needle.
-- @param mixed             needle
-- @param mixed             haystack
-- @param string|null       message
-- @param bool|null         ignoreCase
-- @param bool|null         checkForObjectIdentity
-- @param bool|null         checkForNonObjectIdentity

function _M:assertNotContains(needle, haystack, message, ignoreCase, checkForObjectIdentity, checkForNonObjectIdentity)

    checkForNonObjectIdentity = checkForNonObjectIdentity or false
    checkForObjectIdentity = lf.needTrue(checkForObjectIdentity)
    ignoreCase = ignoreCase or false
    message = message or ''
    local constraint
    if lf.isTbl(haystack) or lf.isObj(haystack) and haystack:__is('eachable') then
        constraint = new('unit.constraint.logicalNot', new('unit.constraint.eachableContains', needle, checkForObjectIdentity, checkForNonObjectIdentity))
     elseif lf.isStr(haystack) then
        if not lf.isStr(needle) then
            InvalidArgument(1, 'string')
        end
        constraint = new('unit.constraint.logicalNot', new('unit.constraint.stringContains', needle, ignoreCase))
     else 
        InvalidArgument(2, 'array, eachable or string')
    end
    self:assertThat(haystack, constraint, message)
end

-- Asserts that a haystack that is stored in a static attribute of a class
-- or an attribute of an object does not contain a needle.
-- @param mixed         needle
-- @param string        haystackAttributeName
-- @param string|object haystackClassOrObject
-- @param string        message
-- @param bool          ignoreCase
-- @param bool          checkForObjectIdentity
-- @param bool          checkForNonObjectIdentity

function _M:assertAttributeNotContains(needle, haystackAttributeName, haystackClassOrObject, message, ignoreCase, checkForObjectIdentity, checkForNonObjectIdentity)

    checkForNonObjectIdentity = checkForNonObjectIdentity or false
    checkForObjectIdentity = lf.needTrue(checkForObjectIdentity)
    ignoreCase = ignoreCase or false
    message = message or ''
    self:assertNotContains(needle, self:readAttribute(haystackClassOrObject, haystackAttributeName), message, ignoreCase, checkForObjectIdentity, checkForNonObjectIdentity)
end

-- Asserts that a haystack contains only values of a given type.
-- @param string type
-- @param mixed  haystack
-- @param bool   isNativeType
-- @param string|null message

function _M:assertContainsOnly(type, haystack, isNativeType, message)

    message = message or ''
    if not (lf.isTbl(haystack) or lf.isObj(haystack) and haystack:__is('eachable')) then
        InvalidArgument(2, 'array or eachable')
    end
    if isNativeType == nil then
        isNativeType = Type.isType(type)
    end
    self:assertThat(haystack, new('unit.constraint.eachableContainsOnly', type, isNativeType), message)
end

-- Asserts that a haystack contains only instances of a given classname
-- @param string            classname
-- @param table|eachable haystack
-- @param string            message

function _M:assertContainsOnlyInstancesOf(classname, haystack, message)

    message = message or ''
    if not (lf.isTbl(haystack) or lf.isObj(haystack) and haystack:__is('eachable')) then
        InvalidArgument(2, 'array or eachable')
    end
    self:assertThat(haystack, new('unit.constraint.eachableContainsOnly', classname, false), message)
end

-- Asserts that a haystack that is stored in a static attribute of a class
-- or an attribute of an object contains only values of a given type.
-- @param string        type
-- @param string        haystackAttributeName
-- @param string|object haystackClassOrObject
-- @param bool          isNativeType
-- @param string        message

function _M:assertAttributeContainsOnly(type, haystackAttributeName, haystackClassOrObject, isNativeType, message)

    message = message or ''
    self:assertContainsOnly(type, self:readAttribute(haystackClassOrObject, haystackAttributeName), isNativeType, message)
end

-- Asserts that a haystack does not contain only values of a given type.
-- @param string type
-- @param mixed  haystack
-- @param bool   isNativeType
-- @param string|null message

function _M:assertNotContainsOnly(type, haystack, isNativeType, message)

    message = message or ''
    if not (lf.isTbl(haystack) or lf.isObj(haystack) and haystack:__is('eachable')) then
        InvalidArgument(2, 'array or eachable')
    end
    if isNativeType == nil then
        isNativeType = Type.isType(type)
    end
    self:assertThat(haystack, new('unit.constraint.logicalNot', new('unit.constraint.eachableContainsOnly', type, isNativeType)), message)
end

-- Asserts that a haystack that is stored in a static attribute of a class
-- or an attribute of an object does not contain only values of a given
-- type.
-- @param string        type
-- @param string        haystackAttributeName
-- @param string|object haystackClassOrObject
-- @param bool          isNativeType
-- @param string        message

function _M:assertAttributeNotContainsOnly(type, haystackAttributeName, haystackClassOrObject, isNativeType, message)

    message = message or ''
    self:assertNotContainsOnly(type, self:readAttribute(haystackClassOrObject, haystackAttributeName), isNativeType, message)
end

-- Asserts the number of elements of an table, Countable or eachable.
-- @param int           expectedCount
-- @param mixed         haystack
-- @param string|null   message

function _M:assertCount(expectedCount, haystack, message)

    message = message or ''
    if not lf.isNum(expectedCount) then
        InvalidArgument(1, 'integer')
    end
    local invalid
    if lf.isObj(haystack) then
        if not haystack:__is('countable') and not haystack:__is('eachable') then
            invalid = true
        end
    else
        if not lf.isTbl(haystack) then
            invalid = true
        end
    end
    if invalid then
        InvalidArgument(2, 'countable or eachable or table')
    end
    
    self:assertThat(haystack, new('unit.constraint.count', expectedCount), message)
end

-- Asserts the number of elements of an table, Countable or eachable
-- that is stored in an attribute.
-- @param int           expectedCount
-- @param string        haystackAttributeName
-- @param string|object haystackClassOrObject
-- @param string        message

function _M:assertAttributeCount(expectedCount, haystackAttributeName, haystackClassOrObject, message)

    message = message or ''
    self:assertCount(expectedCount, self:readAttribute(haystackClassOrObject, haystackAttributeName), message)
end

-- Asserts the number of elements of an table, Countable or eachable.
-- @param int    expectedCount
-- @param mixed  haystack
-- @param string|null message

function _M:assertNotCount(expectedCount, haystack, message)

    message = message or ''
    if not lf.isNum(expectedCount) then
        InvalidArgument(1, 'integer')
    end
    if not haystack:__is('Countable') and not haystack:__is('eachable') and not lf.isTbl(haystack) then
        InvalidArgument(2, 'countable or eachable')
    end
    local constraint = new('unit.constraint.logicalNot', new('unit.constraint.count', expectedCount))
    self:assertThat(haystack, constraint, message)
end

-- Asserts the number of elements of an table, Countable or eachable
-- that is stored in an attribute.
-- @param int           expectedCount
-- @param string        haystackAttributeName
-- @param string|object haystackClassOrObject
-- @param string        message

function _M:assertAttributeNotCount(expectedCount, haystackAttributeName, haystackClassOrObject, message)

    message = message or ''
    self:assertNotCount(expectedCount, self:readAttribute(haystackClassOrObject, haystackAttributeName), message)
end

-- Asserts that two variables are equal.
-- @param mixed             expected
-- @param mixed|null        actual
-- @param string|null       message
-- @param float|null        delta
-- @param int|null          maxDepth
-- @param bool|null         canonicalize
-- @param bool|null         ignoreCase

function _M:assertEquals(expected, actual, message, delta, maxDepth, canonicalize, ignoreCase)

    ignoreCase = ignoreCase or false
    canonicalize = canonicalize or false
    maxDepth = maxDepth or 10
    delta = delta or 0.0
    message = message or ''
    local constraint = new('unit.constraint.isEqual', expected, delta, maxDepth, canonicalize, ignoreCase)
    self:assertThat(actual, constraint, message)
end

-- Asserts that a variable is equal to an attribute of an object.
-- @param mixed         expected
-- @param string        actualAttributeName
-- @param string|object actualClassOrObject
-- @param string        message
-- @param float         delta
-- @param int           maxDepth
-- @param bool          canonicalize
-- @param bool          ignoreCase

function _M:assertAttributeEquals(expected, actualAttributeName, actualClassOrObject, message, delta, maxDepth, canonicalize, ignoreCase)

    ignoreCase = ignoreCase or false
    canonicalize = canonicalize or false
    maxDepth = maxDepth or 10
    delta = delta or 0.0
    message = message or ''
    self:assertEquals(expected, self:readAttribute(actualClassOrObject, actualAttributeName), message, delta, maxDepth, canonicalize, ignoreCase)
end

-- Asserts that two variables are not equal.
-- @param mixed  expected
-- @param mixed  actual
-- @param string|null message
-- @param float  delta
-- @param int    maxDepth
-- @param bool   canonicalize
-- @param bool   ignoreCase

function _M:assertNotEquals(expected, actual, message, delta, maxDepth, canonicalize, ignoreCase)

    ignoreCase = ignoreCase or false
    canonicalize = canonicalize or false
    maxDepth = maxDepth or 10
    delta = delta or 0.0
    message = message or ''
    local constraint = new('unit.constraint.logicalNot', new('unit.constraint.isEqual', expected, delta, maxDepth, canonicalize, ignoreCase))
    self:assertThat(actual, constraint, message)
end

-- Asserts that a variable is not equal to an attribute of an object.
-- @param mixed         expected
-- @param string        actualAttributeName
-- @param string|object actualClassOrObject
-- @param string        message
-- @param float         delta
-- @param int           maxDepth
-- @param bool          canonicalize
-- @param bool          ignoreCase

function _M:assertAttributeNotEquals(expected, actualAttributeName, actualClassOrObject, message, delta, maxDepth, canonicalize, ignoreCase)

    ignoreCase = ignoreCase or false
    canonicalize = canonicalize or false
    maxDepth = maxDepth or 10
    delta = delta or 0.0
    message = message or ''
    self:assertNotEquals(expected, self:readAttribute(actualClassOrObject, actualAttributeName), message, delta, maxDepth, canonicalize, ignoreCase)
end

-- Asserts that a variable is empty.
-- @param mixed|null        actual
-- @param string|null       message

function _M:assertEmpty(actual, message)

    message = message or ''
    self:assertThat(actual, self:isEmpty(), message)
end

-- Asserts that a static attribute of a class or an attribute of an object
-- is empty.
-- @param string        haystackAttributeName
-- @param string|object haystackClassOrObject
-- @param string        message

function _M:assertAttributeEmpty(haystackAttributeName, haystackClassOrObject, message)

    message = message or ''
    self:assertEmpty(self:readAttribute(haystackClassOrObject, haystackAttributeName), message)
end

-- Asserts that a variable is not empty.
-- @param mixed  actual
-- @param string|null message
-- @throws AssertionFailedError

function _M:assertNotEmpty(actual, message)

    message = message or ''
    self:assertThat(actual, self:logicalNot(self:isEmpty()), message)
end

-- Asserts that a static attribute of a class or an attribute of an object
-- is not empty.
-- @param string        haystackAttributeName
-- @param string|object haystackClassOrObject
-- @param string        message

function _M:assertAttributeNotEmpty(haystackAttributeName, haystackClassOrObject, message)

    message = message or ''
    self:assertNotEmpty(self:readAttribute(haystackClassOrObject, haystackAttributeName), message)
end

-- Asserts that a value is greater than another value.
-- @param mixed  expected
-- @param mixed  actual
-- @param string|null message

function _M:assertGreaterThan(expected, actual, message)

    message = message or ''
    self:assertThat(actual, self:greaterThan(expected), message)
end

-- Asserts that an attribute is greater than another value.
-- @param mixed         expected
-- @param string        actualAttributeName
-- @param string|object actualClassOrObject
-- @param string        message

function _M:assertAttributeGreaterThan(expected, actualAttributeName, actualClassOrObject, message)

    message = message or ''
    self:assertGreaterThan(expected, self:readAttribute(actualClassOrObject, actualAttributeName), message)
end

-- Asserts that a value is greater than or equal to another value.
-- @param mixed  expected
-- @param mixed  actual
-- @param string|null message

function _M:assertGreaterThanOrEqual(expected, actual, message)

    message = message or ''
    self:assertThat(actual, self:greaterThanOrEqual(expected), message)
end

-- Asserts that an attribute is greater than or equal to another value.
-- @param mixed         expected
-- @param string        actualAttributeName
-- @param string|object actualClassOrObject
-- @param string        message

function _M:assertAttributeGreaterThanOrEqual(expected, actualAttributeName, actualClassOrObject, message)

    message = message or ''
    self:assertGreaterThanOrEqual(expected, self:readAttribute(actualClassOrObject, actualAttributeName), message)
end

-- Asserts that a value is smaller than another value.
-- @param mixed  expected
-- @param mixed  actual
-- @param string|null message

function _M:assertLessThan(expected, actual, message)

    message = message or ''
    self:assertThat(actual, self:lessThan(expected), message)
end

-- Asserts that an attribute is smaller than another value.
-- @param mixed         expected
-- @param string        actualAttributeName
-- @param string|object actualClassOrObject
-- @param string        message

function _M:assertAttributeLessThan(expected, actualAttributeName, actualClassOrObject, message)

    message = message or ''
    self:assertLessThan(expected, self:readAttribute(actualClassOrObject, actualAttributeName), message)
end

-- Asserts that a value is smaller than or equal to another value.
-- @param mixed  expected
-- @param mixed  actual
-- @param string|null message

function _M:assertLessThanOrEqual(expected, actual, message)

    message = message or ''
    self:assertThat(actual, self:lessThanOrEqual(expected), message)
end

-- Asserts that an attribute is smaller than or equal to another value.
-- @param mixed         expected
-- @param string        actualAttributeName
-- @param string|object actualClassOrObject
-- @param string        message

function _M:assertAttributeLessThanOrEqual(expected, actualAttributeName, actualClassOrObject, message)

    message = message or ''
    self:assertLessThanOrEqual(expected, self:readAttribute(actualClassOrObject, actualAttributeName), message)
end

-- Asserts that the contents of one file is equal to the contents of another
-- file.
-- @param string expected
-- @param string actual
-- @param string|null message
-- @param bool   canonicalize
-- @param bool   ignoreCase

function _M:assertFileEquals(expected, actual, message, canonicalize, ignoreCase)

    ignoreCase = ignoreCase or false
    canonicalize = canonicalize or false
    message = message or ''
    self:assertFileExists(expected, message)
    self:assertFileExists(actual, message)
    self:assertEquals(fs.get(expected), fs.get(actual), message, 0, 10, canonicalize, ignoreCase)
end

-- Asserts that the contents of one file is not equal to the contents of
-- another file.
-- @param string expected
-- @param string actual
-- @param string|null message
-- @param bool   canonicalize
-- @param bool   ignoreCase

function _M:assertFileNotEquals(expected, actual, message, canonicalize, ignoreCase)

    ignoreCase = ignoreCase or false
    canonicalize = canonicalize or false
    message = message or ''
    self:assertFileExists(expected, message)
    self:assertFileExists(actual, message)
    self:assertNotEquals(fs.get(expected), fs.get(actual), message, 0, 10, canonicalize, ignoreCase)
end

-- Asserts that the contents of a string is equal
-- to the contents of a file.
-- @param string expectedFile
-- @param string actualString
-- @param string|null message
-- @param bool   canonicalize
-- @param bool   ignoreCase

function _M:assertStringEqualsFile(expectedFile, actualString, message, canonicalize, ignoreCase)

    ignoreCase = ignoreCase or false
    canonicalize = canonicalize or false
    message = message or ''
    self:assertFileExists(expectedFile, message)
    self:assertEquals(fs.get(expectedFile), actualString, message, 0, 10, canonicalize, ignoreCase)
end

-- Asserts that the contents of a string is not equal
-- to the contents of a file.
-- @param string expectedFile
-- @param string actualString
-- @param string|null message
-- @param bool   canonicalize
-- @param bool   ignoreCase

function _M:assertStringNotEqualsFile(expectedFile, actualString, message, canonicalize, ignoreCase)

    ignoreCase = ignoreCase or false
    canonicalize = canonicalize or false
    message = message or ''
    self:assertFileExists(expectedFile, message)
    self:assertNotEquals(fs.get(expectedFile), actualString, message, 0, 10, canonicalize, ignoreCase)
end

-- Asserts that a file/dir is readable.
-- @param string filename
-- @param string|null message

function _M:assertIsReadable(filename, message)

    message = message or ''
    if not lf.isStr(filename) then
        InvalidArgument(1, 'string')
    end
    local constraint = new('unit.constraint.isReadable')
    self:assertThat(filename, constraint, message)
end

-- Asserts that a file/dir exists and is not readable.
-- @param string filename
-- @param string|null message

function _M:assertNotIsReadable(filename, message)

    message = message or ''
    if not lf.isStr(filename) then
        InvalidArgument(1, 'string')
    end
    local constraint = new('unit.constraint.logicalNot', new('unit.constraint.isReadable'))
    self:assertThat(filename, constraint, message)
end

-- Asserts that a file/dir exists and is writable.
-- @param string filename
-- @param string|null message

function _M:assertIsWritable(filename, message)

    message = message or ''
    if not lf.isStr(filename) then
        InvalidArgument(1, 'string')
    end
    local constraint = new('unit.constraint.isWritable')
    self:assertThat(filename, constraint, message)
end

-- Asserts that a file/dir exists and is not writable.
-- @param string filename
-- @param string|null message

function _M:assertNotIsWritable(filename, message)

    message = message or ''
    if not lf.isStr(filename) then
        InvalidArgument(1, 'string')
    end
    local constraint = new('unit.constraint.logicalNot', new('unit.constraint.isWritable'))
    self:assertThat(filename, constraint, message)
end

-- Asserts that a directory exists.
-- @param string directory
-- @param string|null message

function _M:assertDirectoryExists(directory, message)

    message = message or ''
    if not lf.isStr(directory) then
        InvalidArgument(1, 'string')
    end
    local constraint = new('unit.constraint.directoryExists')
    self:assertThat(directory, constraint, message)
end

-- Asserts that a directory does not exist.
-- @param string directory
-- @param string|null message

function _M:assertDirectoryNotExists(directory, message)

    message = message or ''
    if not lf.isStr(directory) then
        InvalidArgument(1, 'string')
    end
    local constraint = new('unit.constraint.logicalNot', new('unit.constraint.directoryExists'))
    self:assertThat(directory, constraint, message)
end

-- Asserts that a directory exists and is readable.
-- @param string directory
-- @param string|null message

function _M:assertDirectoryIsReadable(directory, message)

    message = message or ''
    self:assertDirectoryExists(directory, message)
    self:assertIsReadable(directory, message)
end

-- Asserts that a directory exists and is not readable.
-- @param string directory
-- @param string|null message

function _M:assertDirectoryNotIsReadable(directory, message)

    message = message or ''
    self:assertDirectoryExists(directory, message)
    self:assertNotIsReadable(directory, message)
end

-- Asserts that a directory exists and is writable.
-- @param string directory
-- @param string|null message

function _M:assertDirectoryIsWritable(directory, message)

    message = message or ''
    self:assertDirectoryExists(directory, message)
    self:assertIsWritable(directory, message)
end

-- Asserts that a directory exists and is not writable.
-- @param string directory
-- @param string|null message

function _M:assertDirectoryNotIsWritable(directory, message)

    message = message or ''
    self:assertDirectoryExists(directory, message)
    self:assertNotIsWritable(directory, message)
end

-- Asserts that a file exists.
-- @param string filename
-- @param string|null message

function _M:assertFileExists(filename, message)

    message = message or ''
    if not lf.isStr(filename) then
        InvalidArgument(1, 'string')
    end
    local constraint = new('unit.constraint.fileExists')
    self:assertThat(filename, constraint, message)
end

-- Asserts that a file does not exist.
-- @param string filename
-- @param string|null message

function _M:assertFileNotExists(filename, message)

    message = message or ''
    if not lf.isStr(filename) then
        InvalidArgument(1, 'string')
    end
    local constraint = new('unit.constraint.logicalNot', new('unit.constraint.fileExists'))
    self:assertThat(filename, constraint, message)
end

-- Asserts that a file exists and is readable.
-- @param string file
-- @param string|null message

function _M:assertFileIsReadable(file, message)

    message = message or ''
    self:assertFileExists(file, message)
    self:assertIsReadable(file, message)
end

-- Asserts that a file exists and is not readable.
-- @param string file
-- @param string|null message

function _M:assertFileNotIsReadable(file, message)

    message = message or ''
    self:assertFileExists(file, message)
    self:assertNotIsReadable(file, message)
end

-- Asserts that a file exists and is writable.
-- @param string file
-- @param string|null message

function _M:assertFileIsWritable(file, message)

    message = message or ''
    self:assertFileExists(file, message)
    self:assertIsWritable(file, message)
end

-- Asserts that a file exists and is not writable.
-- @param string file
-- @param string|null message

function _M:assertFileNotIsWritable(file, message)

    message = message or ''
    self:assertFileExists(file, message)
    self:assertNotIsWritable(file, message)
end

-- Asserts that a condition is true.
-- @param mixed|null        condition
-- @param string|null       message

function _M:assertTrue(condition, message)

    message = message or ''
    self:assertThat(condition, self:isTrue(), message)
end

-- Asserts that a condition is not true.
-- @param mixed|null        condition
-- @param string|null       message

function _M:assertNotTrue(condition, message)

    message = message or ''
    self:assertThat(condition, self:logicalNot(self:isTrue()), message)
end

-- Asserts that a condition is false.
-- @param mixed|null        condition
-- @param string|null       message

function _M:assertFalse(condition, message)

    message = message or ''
    self:assertThat(condition, self:isFalse(), message)
end

-- Asserts that a condition is not false.
-- @param mixed|null        condition
-- @param string|null       message

function _M:assertNotFalse(condition, message)

    message = message or ''
    self:assertThat(condition, self:logicalNot(self:isFalse()), message)
end

-- Asserts that a variable is null.
-- @param mixed|null    actual
-- @param string|null   message

function _M:assertNull(actual, message)

    message = message or ''
    self:assertThat(actual, self:isNull(), message)
end

-- Asserts that a variable is not null.
-- @param mixed|null    actual
-- @param string|null   message

function _M:assertNotNull(actual, message)

    message = message or ''
    self:assertThat(actual, self:logicalNot(self:isNull()), message)
end

-- Asserts that a variable is finite.
-- @param mixed  actual
-- @param string|null message

function _M:assertFinite(actual, message)

    message = message or ''
    self:assertThat(actual, self:isFinite(), message)
end

-- Asserts that a variable is infinite.
-- @param mixed  actual
-- @param string|null message

function _M:assertInfinite(actual, message)

    message = message or ''
    self:assertThat(actual, self:isInfinite(), message)
end

-- Asserts that a variable is nan.
-- @param mixed  actual
-- @param string|null message

function _M:assertNan(actual, message)

    message = message or ''
    self:assertThat(actual, self:isNan(), message)
end

-- Asserts that a class has a specified attribute.
-- @param string attributeName
-- @param string className
-- @param string|null message

function _M:assertClassHasAttribute(attributeName, className, message)

    message = message or ''
    if not lf.isStr(attributeName) then
        InvalidArgument(1, 'string')
    end
    if not str.rematch(attributeName, '/[a-zA-Z_\\x7f-\\xff][a-zA-Z0-9_\\x7f-\\xff]*/') then
        InvalidArgument(1, 'valid attribute name')
    end
    if not lf.isStr(className) or not app:hasClass(className) then
        InvalidArgument(2, 'class name', className)
    end
    local constraint = new('unit.constraint.classHasAttribute', attributeName)
    self:assertThat(className, constraint, message)
end

-- Asserts that a class does not have a specified attribute.
-- @param string attributeName
-- @param string className
-- @param string|null message

function _M:assertClassNotHasAttribute(attributeName, className, message)

    message = message or ''
    if not lf.isStr(attributeName) then
        InvalidArgument(1, 'string')
    end
    if not str.rematch(attributeName, '/[a-zA-Z_\\x7f-\\xff][a-zA-Z0-9_\\x7f-\\xff]*/') then
        InvalidArgument(1, 'valid attribute name')
    end
    if not lf.isStr(className) or not app:hasClass(className) then
        InvalidArgument(2, 'class name', className)
    end
    local constraint = new('unit.constraint.logicalNot', new('unit.constraint.classHasAttribute', attributeName))
    self:assertThat(className, constraint, message)
end

-- Asserts that a class has a specified static attribute.
-- @param string attributeName
-- @param string className
-- @param string|null message

function _M:assertClassHasStaticAttribute(attributeName, className, message)

    message = message or ''
    if not lf.isStr(attributeName) then
        InvalidArgument(1, 'string')
    end
    if not str.rematch(attributeName, '/[a-zA-Z_\\x7f-\\xff][a-zA-Z0-9_\\x7f-\\xff]*/') then
        InvalidArgument(1, 'valid attribute name')
    end
    if not lf.isStr(className) or not app:hasClass(className) then
        InvalidArgument(2, 'class name', className)
    end
    local constraint = new('unit.constraint.classHasStaticAttribute', attributeName)
    self:assertThat(className, constraint, message)
end

-- Asserts that a class does not have a specified static attribute.
-- @param string attributeName
-- @param string className
-- @param string|null message

function _M:assertClassNotHasStaticAttribute(attributeName, className, message)

    message = message or ''
    if not lf.isStr(attributeName) then
        InvalidArgument(1, 'string')
    end
    if not str.rematch(attributeName, '/[a-zA-Z_\\x7f-\\xff][a-zA-Z0-9_\\x7f-\\xff]*/') then
        InvalidArgument(1, 'valid attribute name')
    end
    if not lf.isStr(className) or not app:hasClass(className) then
        InvalidArgument(2, 'class name', className)
    end
    local constraint = new('unit.constraint.logicalNot', new('unit.constraint.classHasStaticAttribute', attributeName))
    self:assertThat(className, constraint, message)
end

-- Asserts that an object has a specified attribute.
-- @param string attributeName
-- @param object object
-- @param string|null message

function _M:assertObjectHasAttribute(attributeName, object, message)

    message = message or ''
    if not lf.isStr(attributeName) then
        InvalidArgument(1, 'string')
    end
    if not str.rematch(attributeName, '/[a-zA-Z_\\x7f-\\xff][a-zA-Z0-9_\\x7f-\\xff]*/') then
        InvalidArgument(1, 'valid attribute name')
    end
    if not lf.isObj(object) then
        InvalidArgument(2, 'object')
    end
    local constraint = new('unit.constraint.objectHasAttribute', attributeName)
    self:assertThat(object, constraint, message)
end

-- Asserts that an object does not have a specified attribute.
-- @param string attributeName
-- @param object object
-- @param string|null message

function _M:assertObjectNotHasAttribute(attributeName, object, message)

    message = message or ''
    if not lf.isStr(attributeName) then
        InvalidArgument(1, 'string')
    end
    if not str.rematch(attributeName, '/[a-zA-Z_\\x7f-\\xff][a-zA-Z0-9_\\x7f-\\xff]*/') then
        InvalidArgument(1, 'valid attribute name')
    end
    if not lf.isObj(object) then
        InvalidArgument(2, 'object')
    end
    local constraint = new('unit.constraint.logicalNot', new('unit.constraint.objectHasAttribute', attributeName))
    self:assertThat(object, constraint, message)
end

-- Asserts that two variables have the same type and value.
-- Used on objects, it asserts that two variables reference
-- the same object.
-- @param mixed|null    expected
-- @param mixed|null    actual
-- @param string|null   message

function _M:assertSame(expected, actual, message)

    message = message or ''
    if lf.isBool(expected) and lf.isBool(actual) then
        self:assertEquals(expected, actual, message)
    else 
        local constraint = new('unit.constraint.isIdentical', expected)
        self:assertThat(actual, constraint, message)
    end
end

-- Asserts that a variable and an attribute of an object have the same type
-- and value.
-- @param mixed         expected
-- @param string        actualAttributeName
-- @param string|object actualClassOrObject
-- @param string        message

function _M:assertAttributeSame(expected, actualAttributeName, actualClassOrObject, message)

    message = message or ''
    self:assertSame(expected, self:readAttribute(actualClassOrObject, actualAttributeName), message)
end

-- Asserts that two variables do not have the same type and value.
-- Used on objects, it asserts that two variables do not reference
-- the same object.
-- @param mixed  expected
-- @param mixed  actual
-- @param string|null message

function _M:assertNotSame(expected, actual, message)

    message = message or ''
    if lf.isBool(expected) and lf.isBool(actual) then
        self:assertNotEquals(expected, actual, message)
     else 
        local constraint = new('unit.constraint.logicalNot', new('unit.constraint.isIdentical', expected))
        self:assertThat(actual, constraint, message)
    end
end

-- Asserts that a variable and an attribute of an object do not have the
-- same type and value.
-- @param mixed         expected
-- @param string        actualAttributeName
-- @param string|object actualClassOrObject
-- @param string        message

function _M:assertAttributeNotSame(expected, actualAttributeName, actualClassOrObject, message)

    message = message or ''
    self:assertNotSame(expected, self:readAttribute(actualClassOrObject, actualAttributeName), message)
end

-- Asserts that a variable is of a given type.
-- @param string        expected
-- @param mixed         actual
-- @param string|null   message

function _M:assertInstanceOf(expected, actual, message)

    message = message or ''
    if not (lf.isStr(expected) and (app:hasClass(expected) or app:hasBond(expected))) then
        InvalidArgument(1, 'invalid class or bond name', expected)
    end
    local constraint = new('unit.constraint.isInstanceOf', expected)
    self:assertThat(actual, constraint, message)
end

-- Asserts that an attribute is of a given type.
-- @param string        expected
-- @param string        attributeName
-- @param string|object classOrObject
-- @param string        message

function _M:assertAttributeInstanceOf(expected, attributeName, classOrObject, message)

    message = message or ''
    self:assertInstanceOf(expected, self:readAttribute(classOrObject, attributeName), message)
end

-- Asserts that a variable is not of a given type.
-- @param string expected
-- @param mixed  actual
-- @param string|null message

function _M:assertNotInstanceOf(expected, actual, message)

    message = message or ''
    if not (lf.isStr(expected) and (app:hasClass(expected) or app:hasBond(expected))) then
        InvalidArgument(1, 'class or interface name')
    end
    local constraint = new('unit.constraint.logicalNot', new('unit.constraint.isInstanceOf', expected))
    self:assertThat(actual, constraint, message)
end

-- Asserts that an attribute is of a given type.
-- @param string        expected
-- @param string        attributeName
-- @param string|object classOrObject
-- @param string        message

function _M:assertAttributeNotInstanceOf(expected, attributeName, classOrObject, message)

    message = message or ''
    self:assertNotInstanceOf(expected, self:readAttribute(classOrObject, attributeName), message)
end

-- Asserts that a variable is of a given type.
-- @param string expected
-- @param mixed  actual
-- @param string|null message

function _M:assertInternalType(expected, actual, message)

    message = message or ''
    if not lf.isStr(expected) then
        InvalidArgument(1, 'string')
    end
    local constraint = new('unit.constraint.isType', expected)
    self:assertThat(actual, constraint, message)
end

-- Asserts that an attribute is of a given type.
-- @param string        expected
-- @param string        attributeName
-- @param string|object classOrObject
-- @param string        message

function _M:assertAttributeInternalType(expected, attributeName, classOrObject, message)

    message = message or ''
    self:assertInternalType(expected, self:readAttribute(classOrObject, attributeName), message)
end

-- Asserts that a variable is not of a given type.
-- @param string expected
-- @param mixed  actual
-- @param string|null message

function _M:assertNotInternalType(expected, actual, message)

    message = message or ''
    if not lf.isStr(expected) then
        InvalidArgument(1, 'string')
    end
    local constraint = new('unit.constraint.logicalNot', new('unit.constraint.isType', expected))
    self:assertThat(actual, constraint, message)
end

-- Asserts that an attribute is of a given type.
-- @param string        expected
-- @param string        attributeName
-- @param string|object classOrObject
-- @param string        message

function _M:assertAttributeNotInternalType(expected, attributeName, classOrObject, message)

    message = message or ''
    self:assertNotInternalType(expected, self:readAttribute(classOrObject, attributeName), message)
end

-- Asserts that a string matches a given regular expression.
-- @param string pattern
-- @param string string
-- @param string|null message

function _M:assertRegExp(pattern, string, message)

    message = message or ''
    if not lf.isStr(pattern) then
        InvalidArgument(1, 'string')
    end
    if not lf.isStr(string) then
        InvalidArgument(2, 'string')
    end
    local constraint = new('unit.constraint.regularExpression', pattern)
    self:assertThat(string, constraint, message)
end

-- Asserts that a string does not match a given regular expression.
-- @param string pattern
-- @param string string
-- @param string|null message

function _M:assertNotRegExp(pattern, string, message)

    message = message or ''
    if not lf.isStr(pattern) then
        InvalidArgument(1, 'string')
    end
    if not lf.isStr(string) then
        InvalidArgument(2, 'string')
    end
    local constraint = new('unit.constraint.logicalNot', new('unit.constraint.regularExpression', pattern))
    self:assertThat(string, constraint, message)
end

-- Assert that the size of two tables (or `Countable` or `eachable` objects)
-- is the same.
-- @param table|Countable|eachable expected
-- @param table|Countable|eachable actual
-- @param string                      message

function _M:assertSameSize(expected, actual, message)

    message = message or ''
    if not expected:__is('Countable') and not expected:__is('eachable') and not lf.isTbl(expected) then
        InvalidArgument(1, 'countable or eachable')
    end
    if not actual:__is('Countable') and not actual:__is('eachable') and not lf.isTbl(actual) then
        InvalidArgument(2, 'countable or eachable')
    end
    self:assertThat(actual, new('unit.constraint.sameSize', expected), message)
end

-- Assert that the size of two tables (or `Countable` or `eachable` objects)
-- is not the same.
-- @param table|Countable|eachable expected
-- @param table|Countable|eachable actual
-- @param string                      message

function _M:assertNotSameSize(expected, actual, message)

    message = message or ''
    if not expected:__is('Countable') and not expected:__is('eachable') and not lf.isTbl(expected) then
        InvalidArgument(1, 'countable or eachable')
    end
    if not actual:__is('Countable') and not actual:__is('eachable') and not lf.isTbl(actual) then
        InvalidArgument(2, 'countable or eachable')
    end
    local constraint = new('unit.constraint.logicalNot', new('unit.constraint.sameSize', expected))
    self:assertThat(actual, constraint, message)
end

-- Asserts that a string matches a given format string.
-- @param string format
-- @param string string
-- @param string|null message

function _M:assertStringMatchesFormat(format, string, message)

    message = message or ''
    if not lf.isStr(format) then
        InvalidArgument(1, 'string')
    end
    if not lf.isStr(string) then
        InvalidArgument(2, 'string')
    end
    local constraint = new('unit.constraint.stringMatchesFormatDescription', format)
    self:assertThat(string, constraint, message)
end

-- Asserts that a string does not match a given format string.
-- @param string format
-- @param string string
-- @param string|null message

function _M:assertStringNotMatchesFormat(format, string, message)

    message = message or ''
    if not lf.isStr(format) then
        InvalidArgument(1, 'string')
    end
    if not lf.isStr(string) then
        InvalidArgument(2, 'string')
    end
    local constraint = new('unit.constraint.logicalNot', new('unit.constraint.stringMatchesFormatDescription', format))
    self:assertThat(string, constraint, message)
end

-- Asserts that a string matches a given format file.
-- @param string formatFile
-- @param string string
-- @param string|null message

function _M:assertStringMatchesFormatFile(formatFile, string, message)

    message = message or ''
    self:assertFileExists(formatFile, message)
    if not lf.isStr(string) then
        InvalidArgument(2, 'string')
    end
    local constraint = new('unit.constraint.stringMatchesFormatDescription', fs.get(formatFile))
    self:assertThat(string, constraint, message)
end

-- Asserts that a string does not match a given format string.
-- @param string formatFile
-- @param string string
-- @param string|null message

function _M:assertStringNotMatchesFormatFile(formatFile, string, message)

    message = message or ''
    self:assertFileExists(formatFile, message)
    if not lf.isStr(string) then
        InvalidArgument(2, 'string')
    end
    local constraint = new('unit.constraint.logicalNot', new('unit.constraint.stringMatchesFormatDescription', fs.get(formatFile)))
    self:assertThat(string, constraint, message)
end

-- Asserts that a string starts with a given prefix.
-- @param string prefix
-- @param string string
-- @param string|null message

function _M:assertStringStartsWith(prefix, string, message)

    message = message or ''
    if not lf.isStr(prefix) then
        InvalidArgument(1, 'string')
    end
    if not lf.isStr(string) then
        InvalidArgument(2, 'string')
    end
    local constraint = new('unit.constraint.stringStartsWith', prefix)
    self:assertThat(string, constraint, message)
end

-- Asserts that a string starts not with a given prefix.
-- @param string prefix
-- @param string string
-- @param string|null message

function _M:assertStringStartsNotWith(prefix, string, message)

    message = message or ''
    if not lf.isStr(prefix) then
        InvalidArgument(1, 'string')
    end
    if not lf.isStr(string) then
        InvalidArgument(2, 'string')
    end
    local constraint = new('unit.constraint.logicalNot', new('unit.constraint.stringStartsWith', prefix))
    self:assertThat(string, constraint, message)
end

-- Asserts that a string ends with a given suffix.
-- @param string suffix
-- @param string string
-- @param string|null message

function _M:assertStringEndsWith(suffix, string, message)

    message = message or ''
    if not lf.isStr(suffix) then
        InvalidArgument(1, 'string')
    end
    if not lf.isStr(string) then
        InvalidArgument(2, 'string')
    end
    local constraint = new('unit.constraint.stringEndsWith', suffix)
    self:assertThat(string, constraint, message)
end

-- Asserts that a string ends not with a given suffix.
-- @param string suffix
-- @param string string
-- @param string|null message

function _M:assertStringEndsNotWith(suffix, string, message)

    message = message or ''
    if not lf.isStr(suffix) then
        InvalidArgument(1, 'string')
    end
    if not lf.isStr(string) then
        InvalidArgument(2, 'string')
    end
    local constraint = new('unit.constraint.logicalNot', new('unit.constraint.stringEndsWith', suffix))
    self:assertThat(string, constraint, message)
end

-- Asserts that two XML files are equal.
-- @param string expectedFile
-- @param string actualFile
-- @param string|null message

function _M:assertXmlFileEqualsXmlFile(expectedFile, actualFile, message)

    message = message or ''
    local expected = Xml.loadFile(expectedFile)
    local actual = Xml.loadFile(actualFile)
    self:assertEquals(expected, actual, message)
end

-- Asserts that two XML files are not equal.
-- @param string expectedFile
-- @param string actualFile
-- @param string|null message

function _M:assertXmlFileNotEqualsXmlFile(expectedFile, actualFile, message)

    message = message or ''
    local expected = Xml.loadFile(expectedFile)
    local actual = Xml.loadFile(actualFile)
    self:assertNotEquals(expected, actual, message)
end

-- Asserts that two XML documents are equal.
-- @param string expectedFile
-- @param string actualXml
-- @param string|null message

function _M:assertXmlStringEqualsXmlFile(expectedFile, actualXml, message)

    message = message or ''
    local expected = Xml.loadFile(expectedFile)
    local actual = Xml.load(actualXml)
    self:assertEquals(expected, actual, message)
end

-- Asserts that two XML documents are not equal.
-- @param string expectedFile
-- @param string actualXml
-- @param string|null message

function _M:assertXmlStringNotEqualsXmlFile(expectedFile, actualXml, message)

    message = message or ''
    local expected = Xml.loadFile(expectedFile)
    local actual = Xml.load(actualXml)
    self:assertNotEquals(expected, actual, message)
end

-- Asserts that two XML documents are equal.
-- @param string expectedXml
-- @param string actualXml
-- @param string|null message

function _M:assertXmlStringEqualsXmlString(expectedXml, actualXml, message)

    message = message or ''
    local expected = Xml.load(expectedXml)
    local actual = Xml.load(actualXml)
    self:assertEquals(expected, actual, message)
end

-- Asserts that two XML documents are not equal.
-- @param string expectedXml
-- @param string actualXml
-- @param string|null message

function _M:assertXmlStringNotEqualsXmlString(expectedXml, actualXml, message)

    message = message or ''
    local expected = Xml.load(expectedXml)
    local actual = Xml.load(actualXml)
    self:assertNotEquals(expected, actual, message)
end

-- Asserts that a hierarchy of DOMElements matches.
-- @param DOMElement expectedElement
-- @param DOMElement actualElement
-- @param bool       checkAttributes
-- @param string     message

function _M:assertEqualXMLStructure(expectedElement, actualElement, checkAttributes, message)

    message = message or ''
    checkAttributes = checkAttributes or false
    local actualAttribute
    local expectedAttribute
    local tmp = new('unit.constraint.dOMDocument')
    expectedElement = tmp:importNode(expectedElement, true)
    tmp = new('unit.constraint.dOMDocument')
    actualElement = tmp:importNode(actualElement, true)
    unset(tmp)
    self:assertEquals(expectedElement.tagName, actualElement.tagName, message)
    if checkAttributes then
        self:assertEquals(expectedElement.attributes.length, actualElement.attributes.length, sprintf('%s%sNumber of attributes on node "%s" does not match', message, not lf.isEmpty(message) and "\n" or '', expectedElement.tagName))
        for i = 0 + 1,expectedElement.attributes.length + 1 do
            expectedAttribute = expectedElement.attributes:item(i)
            actualAttribute = actualElement.attributes:getNamedItem(expectedAttribute.name)
            if not actualAttribute then
                self:fail(sprintf('%s%sCould not find attribute "%s" on node "%s"', message, not lf.isEmpty(message) and "\n" or '', expectedAttribute.name, expectedElement.tagName))
            end
        end
    end
    Xml.removeCharacterDataNodes(expectedElement)
    Xml.removeCharacterDataNodes(actualElement)
    self:assertEquals(expectedElement.childNodes.length, actualElement.childNodes.length, sprintf('%s%sNumber of child nodes of "%s" differs', message, not lf.isEmpty(message) and "\n" or '', expectedElement.tagName))
    for i = 0 + 1,expectedElement.childNodes.length + 1 do
        self:assertEqualXMLStructure(expectedElement.childNodes:item(i), actualElement.childNodes:item(i), checkAttributes, message)
    end
end

-- Evaluates a PHPUnit_Framework_Constraint matcher object.
-- @param mixed|null            value
-- @param unit.constraint       constraint
-- @param string|null           message

function _M:assertThat(value, constraint, message)

    lx.G('lxunitLastAssertLine', debug.getinfo(3).currentline)

    message = message or ''
    static.count = static.count + constraint:count()

    constraint:evaluate(value, message)
end

-- Asserts that a string is a valid JSON string.
-- @param string actualJson
-- @param string|null message

function _M:assertJson(actualJson, message)

    message = message or ''
    if not lf.isStr(actualJson) then
        InvalidArgument(1, 'string')
    end
    self:assertThat(actualJson, self:isJson(), message)
end

-- Asserts that two given JSON encoded objects or tables are equal.
-- @param string expectedJson
-- @param string actualJson
-- @param string|null message

function _M:assertJsonStringEqualsJsonString(expectedJson, actualJson, message)

    message = message or ''
    self:assertJson(expectedJson, message)
    self:assertJson(actualJson, message)
    local constraint = new('unit.constraint.jsonMatches', expectedJson)
    self:assertThat(actualJson, constraint, message)
end

-- Asserts that two given JSON encoded objects or tables are not equal.
-- @param string expectedJson
-- @param string actualJson
-- @param string|null message

function _M:assertJsonStringNotEqualsJsonString(expectedJson, actualJson, message)

    message = message or ''
    self:assertJson(expectedJson, message)
    self:assertJson(actualJson, message)
    local constraint = new('unit.constraint.jsonMatches', expectedJson)
    self:assertThat(actualJson, new('unit.constraint.logicalNot', constraint), message)
end

-- Asserts that the generated JSON encoded object and the content of the given file are equal.
-- @param string expectedFile
-- @param string actualJson
-- @param string|null message

function _M:assertJsonStringEqualsJsonFile(expectedFile, actualJson, message)

    message = message or ''
    self:assertFileExists(expectedFile, message)
    local expectedJson = fs.get(expectedFile)
    self:assertJson(expectedJson, message)
    self:assertJson(actualJson, message)
    local constraint = new('unit.constraint.jsonMatches', expectedJson)
    self:assertThat(actualJson, constraint, message)
end

-- Asserts that the generated JSON encoded object and the content of the given file are not equal.
-- @param string expectedFile
-- @param string actualJson
-- @param string|null message

function _M:assertJsonStringNotEqualsJsonFile(expectedFile, actualJson, message)

    message = message or ''
    self:assertFileExists(expectedFile, message)
    local expectedJson = fs.get(expectedFile)
    self:assertJson(expectedJson, message)
    self:assertJson(actualJson, message)
    local constraint = new('unit.constraint.jsonMatches', expectedJson)
    self:assertThat(actualJson, new('unit.constraint.logicalNot', constraint), message)
end

-- Asserts that two JSON files are equal.
-- @param string expectedFile
-- @param string actualFile
-- @param string|null message

function _M:assertJsonFileEqualsJsonFile(expectedFile, actualFile, message)

    message = message or ''
    self:assertFileExists(expectedFile, message)
    self:assertFileExists(actualFile, message)
    local actualJson = fs.get(actualFile)
    local expectedJson = fs.get(expectedFile)
    self:assertJson(expectedJson, message)
    self:assertJson(actualJson, message)
    local constraintExpected = new('unit.constraint.jsonMatches', expectedJson)
    local constraintActual = new('unit.constraint.jsonMatches', actualJson)
    self:assertThat(expectedJson, constraintActual, message)
    self:assertThat(actualJson, constraintExpected, message)
end

-- Asserts that two JSON files are not equal.
-- @param string expectedFile
-- @param string actualFile
-- @param string|null message

function _M:assertJsonFileNotEqualsJsonFile(expectedFile, actualFile, message)

    message = message or ''
    self:assertFileExists(expectedFile, message)
    self:assertFileExists(actualFile, message)
    local actualJson = fs.get(actualFile)
    local expectedJson = fs.get(expectedFile)
    self:assertJson(expectedJson, message)
    self:assertJson(actualJson, message)
    local constraintExpected = new('unit.constraint.jsonMatches', expectedJson)
    local constraintActual = new('unit.constraint.jsonMatches', actualJson)
    self:assertThat(expectedJson, new('unit.constraint.logicalNot', constraintActual), message)
    self:assertThat(actualJson, new('unit.constraint.logicalNot', constraintExpected), message)
end

-- Returns a unit.constraint.and matcher object.
-- @return unit.constraint.logicalAnd

function _M:logicalAnd()

    local constraints = func_get_args()
    local constraint = new('unit.constraint.logicalAnd')
    constraint:setConstraints(constraints)
    
    return constraint
end

-- Returns a unit.constraint.or matcher object.
-- @return unit.constraint.logicalOr

function _M:logicalOr()

    local constraints = func_get_args()
    local constraint = new('unit.constraint.logicalOr')
    constraint:setConstraints(constraints)
    
    return constraint
end

-- Returns a unit.constraint.not matcher object.
-- @param unit.constraint constraint
-- @return unit.constraint.logicalNot

function _M:logicalNot(constraint)

    return new('unit.constraint.logicalNot', constraint)
end

-- Returns a unit.constraint.xor matcher object.
-- @return unit.constraint.logicalXor

function _M:logicalXor()

    local constraints = func_get_args()
    local constraint = new('unit.constraint.logicalXor')
    constraint:setConstraints(constraints)
    
    return constraint
end

-- Returns a unit.constraint.isAnything matcher object.
-- @return unit.constraint.isAnything

function _M:anything()

    return new('unit.constraint.isAnything')
end

-- Returns a unit.constraint.isTrue matcher object.
-- @return unit.constraint.isTrue

function _M:isTrue()

    return new('unit.constraint.isTrue')
end

-- Returns a unit.constraint.callback matcher object.
-- @param func callback
-- @return Callback

function _M:callback(callback)

    return new('unit.constraint.callback', callback)
end

-- Returns a unit.constraint.isFalse matcher object.
-- @return unit.constraint.isFalse

function _M:isFalse()

    return new('unit.constraint.isFalse')
end

-- Returns a unit.constraint.isJson matcher object.
-- @return unit.constraint.isJson

function _M:isJson()

    return new('unit.constraint.isJson')
end

-- Returns a unit.constraint.isNull matcher object.
-- @return unit.constraint.isNull

function _M:isNull()

    return new('unit.constraint.isNull')
end

-- Returns a unit.constraint.isFinite matcher object.
-- @return IsFinite

function _M:isFinite()

    return new('unit.constraint.isFinite')
end

-- Returns a unit.constraint.isInfinite matcher object.
-- @return IsInfinite

function _M:isInfinite()

    return new('unit.constraint.isInfinite')
end

-- Returns a unit.constraint.isNan matcher object.
-- @return IsNan

function _M:isNan()

    return new('unit.constraint.isNan')
end

-- Returns a unit.constraint.attribute matcher object.
-- @param unit.constraint constraint
-- @param string     attributeName
-- @return Attribute

function _M:attribute(constraint, attributeName)

    return new('unit.constraint.attribute', constraint, attributeName)
end

-- Returns a unit.constraint.eachableContains matcher
-- object.
-- @param mixed value
-- @param bool  checkForObjectIdentity
-- @param bool  checkForNonObjectIdentity
-- @return eachableContains

function _M:contains(value, checkForObjectIdentity, checkForNonObjectIdentity)

    checkForNonObjectIdentity = checkForNonObjectIdentity or false
    checkForObjectIdentity = lf.needTrue(checkForObjectIdentity)
    
    return new('unit.constraint.eachableContains', value, checkForObjectIdentity, checkForNonObjectIdentity)
end

-- Returns a unit.constraint.eachableContainsOnly matcher
-- object.
-- @param string type
-- @return eachableContainsOnly

function _M:containsOnly(type)

    return new('unit.constraint.eachableContainsOnly', type)
end

-- Returns a unit.constraint.eachableContainsOnly matcher
-- object.
-- @param string classname
-- @return eachableContainsOnly

function _M:containsOnlyInstancesOf(classname)

    return new('unit.constraint.eachableContainsOnly', classname, false)
end

-- Returns a unit.constraint.arrayHasKey matcher object.
-- @param mixed     key
-- @return unit.constraint.arrayHasKey

function _M:arrayHasKey(key)

    return new('unit.constraint.arrayHasKey', key)
end

-- Returns a unit.constraint.isEqual matcher object.
-- @param mixed         value
-- @param float|null    delta
-- @param int|null      maxDepth
-- @param bool|null     canonicalize
-- @param bool|null     ignoreCase
-- @return unit.constraint.isEqual

function _M:equalTo(value, delta, maxDepth, canonicalize, ignoreCase)

    ignoreCase = ignoreCase or false
    canonicalize = canonicalize or false
    maxDepth = maxDepth or 10
    delta = delta or 0.0
    
    return new('unit.constraint.isEqual', value, delta, maxDepth, canonicalize, ignoreCase)
end

-- Returns a unit.constraint.isEqual matcher object
-- that is wrapped in a unit.constraint.attribute matcher
-- object.
-- @param string attributeName
-- @param mixed  value
-- @param float  delta
-- @param int    maxDepth
-- @param bool   canonicalize
-- @param bool   ignoreCase
-- @return Attribute

function _M:attributeEqualTo(attributeName, value, delta, maxDepth, canonicalize, ignoreCase)

    ignoreCase = ignoreCase or false
    canonicalize = canonicalize or false
    maxDepth = maxDepth or 10
    delta = delta or 0.0
    
    return self:attribute(self:equalTo(value, delta, maxDepth, canonicalize, ignoreCase), attributeName)
end

-- Returns a unit.constraint.isEmpty matcher object.
-- @return unit.constraint.isEmpty

function _M:isEmpty()

    return new('unit.constraint.isEmpty')
end

-- Returns a unit.constraint.isWritable matcher object.
-- @return IsWritable

function _M:isWritable()

    return new('unit.constraint.isWritable')
end

-- Returns a unit.constraint.isReadable matcher object.
-- @return IsReadable

function _M:isReadable()

    return new('unit.constraint.isReadable')
end

-- Returns a unit.constraint.directoryExists matcher object.
-- @return DirectoryExists

function _M:directoryExists()

    return new('unit.constraint.directoryExists')
end

-- Returns a unit.constraint.fileExists matcher object.
-- @return FileExists

function _M:fileExists()

    return new('unit.constraint.fileExists')
end

-- Returns a unit.constraint.greaterThan matcher object.
-- @param mixed value
-- @return GreaterThan

function _M:greaterThan(value)

    return new('unit.constraint.greaterThan', value)
end

-- Returns a unit.constraint.or matcher object that wraps
-- a unit.constraint.isEqual and a
-- unit.constraint.greaterThan matcher object.
-- @param mixed value
-- @return unit.constraint.logicalOr

function _M:greaterThanOrEqual(value)

    return self:logicalOr(new('unit.constraint.isEqual', value), new('unit.constraint.greaterThan', value))
end

-- Returns a unit.constraint.classHasAttribute matcher object.
-- @param string attributeName
-- @return ClassHasAttribute

function _M:classHasAttribute(attributeName)

    return new('unit.constraint.classHasAttribute', attributeName)
end

-- Returns a unit.constraint.classHasStaticAttribute matcher
-- object.
-- @param string attributeName
-- @return ClassHasStaticAttribute

function _M:classHasStaticAttribute(attributeName)

    return new('unit.constraint.classHasStaticAttribute', attributeName)
end

-- Returns a unit.constraint.objectHasAttribute matcher object.
-- @param string attributeName
-- @return ObjectHasAttribute

function _M:objectHasAttribute(attributeName)

    return new('unit.constraint.objectHasAttribute', attributeName)
end

-- Returns a unit.constraint.isIdentical matcher object.
-- @param mixed value
-- @return IsIdentical

function _M:identicalTo(value)

    return new('unit.constraint.isIdentical', value)
end

-- Returns a unit.constraint.isInstanceOf matcher object.
-- @param string className
-- @return unit.constraint.isInstanceOf

function _M:isInstanceOf(className)

    return new('unit.constraint.isInstanceOf', className)
end

-- Returns a unit.constraint.isType matcher object.
-- @param string type
-- @return IsType

function _M:isType(type)

    return new('unit.constraint.isType', type)
end

-- Returns a unit.constraint.lessThan matcher object.
-- @param mixed value
-- @return LessThan

function _M:lessThan(value)

    return new('unit.constraint.lessThan', value)
end

-- Returns a unit.constraint.or matcher object that wraps
-- a unit.constraint.isEqual and a
-- unit.constraint.lessThan matcher object.
-- @param mixed value
-- @return unit.constraint.logicalOr

function _M:lessThanOrEqual(value)

    return self:logicalOr(new('unit.constraint.isEqual', value), new('unit.constraint.lessThan', value))
end

-- Returns a unit.constraint.pCREMatch matcher object.
-- @param string pattern
-- @return RegularExpression

function _M:matchesRegularExpression(pattern)

    return new('unit.constraint.regularExpression', pattern)
end

-- Returns a unit.constraint.stringMatches matcher object.
-- @param string string
-- @return StringMatchesFormatDescription

function _M:matches(string)

    return new('unit.constraint.stringMatchesFormatDescription', string)
end

-- Returns a unit.constraint.stringStartsWith matcher object.
-- @param mixed prefix
-- @return StringStartsWith

function _M:stringStartsWith(prefix)

    return new('unit.constraint.stringStartsWith', prefix)
end

-- Returns a unit.constraint.stringContains matcher object.
-- @param string string
-- @param bool   case
-- @return StringContains

function _M:stringContains(string, case)

    case = lf.needTrue(case)
    
    return new('unit.constraint.stringContains', string, case)
end

-- Returns a unit.constraint.stringEndsWith matcher object.
-- @param mixed suffix
-- @return StringEndsWith

function _M:stringEndsWith(suffix)

    return new('unit.constraint.stringEndsWith', suffix)
end

-- Returns a unit.constraint.count matcher object.
-- @param int count
-- @return Count

function _M:countOf(count)

    return new('unit.constraint.count', count)
end

-- Fails a test with the given message.
-- @param string|null message
-- @throws AssertionFailedError

function _M:fail(message)

    message = message or ''
    static.count = static.count + 1
    lx.throw('assertionFailedError', message)
end

-- Returns the value of an attribute of a class or an object.
-- This also works for attributes that are declared protected or private.
-- @param string|object classOrObject
-- @param string        attributeName
-- @return mixed
-- @throws Exception

function _M:readAttribute(classOrObject, attributeName)

    if not lf.isStr(attributeName) then
        InvalidArgument(2, 'string')
    end
    if not str.rematch(attributeName, '/[a-zA-Z_\\x7f-\\xff][a-zA-Z0-9_\\x7f-\\xff]*/') then
        InvalidArgument(2, 'valid attribute name')
    end
    if lf.isStr(classOrObject) then
        if not app:hasClass(classOrObject) then
            InvalidArgument(1, 'class name')
        end
        
        return self:getStaticAttribute(classOrObject, attributeName)
    end
    if lf.isObj(classOrObject) then
        
        return self:getObjectAttribute(classOrObject, attributeName)
    end
    InvalidArgument(1, 'class name or object')
end

-- Returns the value of a static attribute.
-- This also works for attributes that are declared protected or private.
-- @param string className
-- @param string attributeName
-- @return mixed
-- @throws Exception

function _M:getStaticAttribute(className, attributeName)

    local attributes
    if not lf.isStr(className) then
        InvalidArgument(1, 'string')
    end
    if not app:hasClass(className) then
        InvalidArgument(1, 'class name')
    end
    if not lf.isStr(attributeName) then
        InvalidArgument(2, 'string')
    end
    if not str.rematch(attributeName, '/[a-zA-Z_\\x7f-\\xff][a-zA-Z0-9_\\x7f-\\xff]*/') then
        InvalidArgument(2, 'valid attribute name')
    end
    local class = new('unit.constraint.reflectionClass', className)
    while class do
        attributes = class:getStaticProperties()
        if tb.has(attributes, attributeName) then
            
            return attributes[attributeName]
        end
        class = class:getParentClass()
    end
    lx.throw('exception', sprintf('Attribute "%s" not found in class.', attributeName))
end

-- Returns the value of an object's attribute.
-- This also works for attributes that are declared protected or private.
-- @param object object
-- @param string attributeName
-- @return mixed
-- @throws Exception

function _M:getObjectAttribute(object, attributeName)

    local reflector
    local value
    if not lf.isObj(object) then
        InvalidArgument(1, 'object')
    end
    if not lf.isStr(attributeName) then
        InvalidArgument(2, 'string')
    end
    if not str.rematch(attributeName, '/[a-zA-Z_\\x7f-\\xff][a-zA-Z0-9_\\x7f-\\xff]*/') then
        InvalidArgument(2, 'valid attribute name')
    end
    try(function()
        attribute = new('unit.constraint.reflectionProperty', object, attributeName)
    end)
    :catch('ReflectionException', function(e) 
        reflector = new('unit.constraint.reflectionObject', object)
        reflector = reflector:getParentClass()
        while reflector do
            try(function()
                attribute = reflector:getProperty(attributeName)

            end)
            :catch('ReflectionException', function(e) 
            end)
            :run()
        end
    end)
    :run()
    if attribute then
        if not attribute or attribute:isPublic() then
            
            return object[attributeName]
        end
        attribute:setAccessible(true)
        value = attribute:getValue(object)
        attribute:setAccessible(false)
        
        return value
    end
    lx.throw('exception', sprintf('Attribute "%s" not found in object.', attributeName))
end

-- Mark the test as incomplete.
-- @param string|null message
-- @throws IncompleteTestError

function _M:markTestIncomplete(message)

    message = message or ''
    lx.throw('incompleteTestError', message)
end

-- Mark the test as skipped.
-- @param string|null message
-- @throws SkippedTestError

function _M:markTestSkipped(message)

    message = message or ''
    lx.throw('skippedTestError', message)
end

-- Return the current assertion count.
-- @return int

function _M.s__.getCount()

    return static.count
end

-- Reset the assertion counter.

function _M.s__.resetCount()

    static.count = 0
end

return _M

