
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'unit.testCase'
}

local app, lf, tb, str, new = lx.kit()
local newCol = Col
local localCol = newCol()
local newList = function(...)
    return lx.n.arr(...):ad()
end

function _M:testFirstReturnsFirstItemInCollection()

    local c = newCol({'foo', 'bar'})
    self:assertEquals('foo', c:first())
end

function _M:testFirstWithCallback()

    local data = newCol({'foo', 'bar', 'baz'})
    local result = data:first(function(value)
        
        return value == 'bar'
    end)
    self:assertEquals('bar', result)
end

function _M:testFirstWithCallbackAndDefault()

    local data = newCol({'foo', 'bar'})
    local result = data:first(function(value)
        
        return value == 'baz'
    end, 'default')
    self:assertEquals('default', result)
end

function _M:testFirstWithDefaultAndWithoutCallback()

    local data = newCol()
    local result = data:first(nil, 'default')
    self:assertEquals('default', result)
end

function _M:testLastReturnsLastItemInCollection()

    local c = newCol({'foo', 'bar'})
    self:assertEquals('bar', c:last())
end

function _M:testLastWithCallback()

    local data = newList({100, 200, 300})
    local result = data:last(function(value)
        
        return value < 250
    end)
    self:assertEquals(200, result)
    result = data:last(function(value, key)
        
        return key < 3
    end)
    self:assertEquals(200, result)
end

function _M:testLastWithCallbackAndDefault()

    local data = newCol({'foo', 'bar'})
    local result = data:last(function(value)
        
        return value == 'baz'
    end, 'default')
    self:assertEquals('default', result)
end

function _M:testLastWithDefaultAndWithoutCallback()

    local data = newCol()
    local result = data:last(nil, 'default')
    self:assertEquals('default', result)
end

function _M:testPopReturnsAndRemovesLastItemInCollection()

    local c = newCol({'foo', 'bar'})
    self:assertEquals('bar', c:pop())
    self:assertEquals('foo', c:first())
end

function _M:testShiftReturnsAndRemovesFirstItemInCollection()

    local c = newCol({'foo', 'bar'})
    self:assertEquals('foo', c:shift())
    self:assertEquals('bar', c:first())
end

function _M:testEmptyCollectionIsEmpty()

    local c = newCol()
    self:assertTrue(c:isEmpty())
end

function _M:testEmptyCollectionIsNotEmpty()

    local c = newCol({'foo', 'bar'})
    self:assertFalse(c:isEmpty())
    self:assertTrue(c:isNotEmpty())
end

function _M:testCollectionIsConstructed()

    local collection = newCol({'foo'})
    self:assertEquals({'foo'}, collection:all())
    collection = newCol({2})
    self:assertEquals({2}, collection:all())
    collection = newCol({false})
    self:assertEquals({false}, collection:all())
    collection = newCol(nil)
    self:assertEquals({}, collection:all())
    collection = newCol()
    self:assertEquals({}, collection:all())
end

function _M:testToJsonEncodesTheJsonableResult()

    local c = self:getMockBuilder('col'):setMethods({'toJson'}):getMock()
    c:expects(self:once()):method('toJson'):will(self:returnValue('["foo"]'))
    local results = c:toJson()

    self:assertJsonStringEqualsJsonString(lf.jsen({'foo'}), results)
end

function _M:testCastingToStringJsonEncodesTheToArrayResult()

    local c = self:getMockBuilder('col'):setMethods({'toJson'}):getMock()
    c:expects(self:once()):method('toJson'):will(self:returnValue('["foo"]'))

    self:assertJsonStringEqualsJsonString(lf.jsen({'foo'}), c:toStr())
end

function _M:testItemAccess()

    local c = newCol({name = 'taylor'}):itemable()
    local item = c.item
    self:assertEquals('taylor', item.name)
    item.name = 'dayle'
    self:assertEquals('dayle', item.name)
    self:assertTrue(item.name)
    item.name = nil
    self:assertFalse(item.name)
    c = newList({'taylor'}):itemable()
    item = c.item
    c:add('jason')
    self:assertEquals('jason', item[2])
end

function _M:testForgetSingleKey()

    local c = newCol({'foo', 'bar'})
    c:forget(1)
    self:assertNull(c('foo'))
    c = newCol({foo = 'bar', baz = 'qux'})
    c:forget('foo')
    self:assertNull(c('foo'))
end

function _M:testForgetArrayOfKeys()

    local c = newCol({'foo', 'bar', 'baz'})
    c:forget({1, 3})
    self:assertFalse(c(1))
    self:assertFalse(c(3))
    self:assertTrue(c(2))
    c = newCol({name = 'taylor', foo = 'bar', baz = 'qux'})
    c:forget({'foo', 'baz'})
    self:assertFalse(c('foo'))
    self:assertFalse(c('baz'))
    self:assertTrue(c('name'))
end

function _M:testCountable()

    local c = newCol({'foo', 'bar'})
    self:assertCount(2, c)
end

function _M:testEachable()

    local c = newCol({'foo'})
    self:assertInstanceOf('eachable', c)
end

function _M:testFilter()

    local c = newCol({{id = 1, name = 'Hello'}, {id = 2, name = 'World'}})
    self:assertEquals({{id = 2, name = 'World'}},
        c:filter(function(item)
        
        return item.id == 2
    end):all())
    c = newCol({'', 'Hello', '', 'World'})
    self:assertEquals({'Hello', 'World'}, c:filter():values():toArr())
    c = newCol({id = 1, first = 'Hello', second = 'World'})
    self:assertEquals({first = 'Hello', second = 'World'}, c:filter(function(item, key)
        
        return key ~= 'id'
    end):all())
end

function _M:testWhere()

    local c = newCol({{v = 1}, {v = 2}, {v = 3}, {v = '3'}, {v = 4}})
    self:assertEquals({{v = 3}, {v = '3'}}, c:where('v', 3):values():all())
    self:assertEquals({{v = 3}, {v = '3'}}, c:where('v', '=', 3):values():all())
    self:assertEquals({{v = 3}, {v = '3'}}, c:where('v', '==', 3):values():all())
    self:assertEquals({{v = 3}}, c:where('v', '===', 3):values():all())
    self:assertEquals({{v = 1}, {v = 2}, {v = 4}}, c:where('v', '<>', 3):values():all())
    self:assertEquals({{v = 1}, {v = 2}, {v = 4}}, c:where('v', '!=', 3):values():all())
    self:assertEquals({{v = 1}, {v = 2}, {v = '3'}, {v = 4}}, c:where('v', '!==', 3):values():all())
    self:assertEquals({{v = 1}, {v = 2}, {v = 3}, {v = '3'}}, c:where('v', '<=', 3):values():all())
    self:assertEquals({{v = 3}, {v = '3'}, {v = 4}}, c:where('v', '>=', 3):values():all())
    self:assertEquals({{v = 1}, {v = 2}}, c:where('v', '<', 3):values():all())
    self:assertEquals({{v = 4}}, c:where('v', '>', 3):values():all())
end

function _M:testWhereStrict()

    local c = newCol({{v = 3}, {v = '3'}})
    self:assertEquals({{v = 3}}, c:whereStrict('v', 3):values():all())
end

function _M:testWhereIn()

    local c = newCol({{v = 1}, {v = 2}, {v = 3}, {v = '3'}, {v = 4}})
    self:assertEquals({{v = 1}, {v = 3}, {v = '3'}}, c:whereIn('v', {1, 3}):values():all())
end

function _M:testWhereInStrict()

    local c = newCol({{v = 1}, {v = 2}, {v = 3}, {v = '3'}, {v = 4}})
    self:assertEquals({{v = 1}, {v = 3}}, c:whereInStrict('v', {1, 3}):values():all())
end

function _M:testWhereNotIn()

    local c = newCol({{v = 1}, {v = 2}, {v = 3}, {v = '3'}, {v = 4}})
    self:assertEquals(
        {{v = 2}, {v = 4}},
        c:whereNotIn('v', {1, 3}):values():all()
    )
end

function _M:testValues()

    local c = newCol({{id = 1, name = 'Hello'}, {id = 2, name = 'World'}})
    self:assertEquals({{id = 2, name = 'World'}}, c:filter(function(item)
        
        return item['id'] == 2
    end):values():all())
end

function _M:testFlatten()

    -- Flat tables are unaffected
    local c = newCol({'#foo', '#bar', '#baz'})
    self:assertEquals({'#foo', '#bar', '#baz'}, c:flatten():all())
    -- Nested tables are flattened with existing flat items
    c = newCol({{'#foo', '#bar'}, '#baz'})
    self:assertEquals({'#foo', '#bar', '#baz'}, c:flatten():all())
    -- Sets of nested tables are flattened
    c = newCol({{'#foo', '#bar'}, {'#baz'}})
    self:assertEquals({'#foo', '#bar', '#baz'}, c:flatten():all())
    -- Deeply nested tables are flattened
    c = newCol({{'#foo', {'#bar'}}, {'#baz'}})
    self:assertEquals({'#foo', '#bar', '#baz'}, c:flatten():all())
    -- Nested collections are flattened alongside tables
    c = newCol({newCol({'#foo', '#bar'}), {'#baz'}})
    self:assertEquals({'#foo', '#bar', '#baz'}, c:flatten():all())
    -- Nested collections containing plain tables are flattened
    c = newCol({newCol({'#foo', {'#bar'}}), {'#baz'}})
    self:assertEquals({'#foo', '#bar', '#baz'}, c:flatten():all())
    -- Nested tables containing collections are flattened
    c = newCol({{'#foo', newCol({'#bar'})}, {'#baz'}})
    self:assertEquals({'#foo', '#bar', '#baz'}, c:flatten():all())
    -- Nested tables containing collections containing tables are flattened
    c = newCol({{'#foo', newCol({'#bar', {'#zap'}})}, {'#baz'}})
    self:assertEquals({'#foo', '#bar', '#zap', '#baz'}, c:flatten():all())
end

function _M:testFlattenWithDepth()

    -- No depth flattens recursively
    local c = newCol({{'#foo', {'#bar', {'#baz'}}}, '#zap'})
    self:assertEquals({'#foo', '#bar', '#baz', '#zap'}, c:flatten():all())
    -- Specifying a depth only flattens to that depth
    c = newCol({{'#foo', {'#bar', {'#baz'}}}, '#zap'})
    self:assertEquals({'#foo', {'#bar', {'#baz'}}, '#zap'}, c:flatten(1):all())
    c = newCol({{'#foo', {'#bar', {'#baz'}}}, '#zap'})
    self:assertEquals({'#foo', '#bar', {'#baz'}, '#zap'}, c:flatten(2):all())
end

function _M:testFlattenIgnoresKeys()

    -- No depth ignores keys
    local c = newCol({'#foo', {key = '#bar'}, {key = '#baz'}, key = '#zap'})
    self:assertEquals({'#foo', '#bar', '#baz', '#zap'}, c:flatten():all())
    -- Depth of 1 ignores keys
    c = newCol({'#foo', {key = '#bar'}, {key = '#baz'}, key = '#zap'})
    self:assertEquals({'#foo', '#bar', '#baz', '#zap'}, c:flatten(1):all())
end

function _M:testMergeNull()

    local c = newCol({name = 'Hello'})
    self:assertEquals({name = 'Hello'}, c:merge(nil):all())
end

function _M:testMergeArray()

    local c = newCol({name = 'Hello'})
    self:assertEquals({name = 'Hello', id = 1}, c:merge({id = 1}):all())
end

function _M:testMergeCollection()

    local c = newCol({name = 'Hello'})
    self:assertEquals({name = 'World', id = 1}, c:merge(newCol({name = 'World', id = 1})):all())
end

function _M:testUnionNull()

    local c = newCol({name = 'Hello'})
    self:assertEquals({name = 'Hello'}, c:union(nil):all())
end

function _M:testUnionArray()

    local c = newCol({name = 'Hello'})
    self:assertEquals({name = 'Hello', id = 1}, c:union({id = 1}):all())
end

function _M:testUnionCollection()

    local c = newCol({name = 'Hello'})

    self:assertEquals(
        {name = 'Hello', id = 1},
        c:union(newCol({name = 'World', id = 1})):all()
    )
end

function _M:testDiffCollection()

    local c = newCol({id = 1, first_word = 'Hello'})
    self:assertEquals({id = 1}, c:diff(
        newCol({first_word = 'Hello', last_word = 'World'})):all()
    )
end

function _M:testDiffNull()

    local c = newCol({id = 1, first_word = 'Hello'})
    self:assertEquals({id = 1, first_word = 'Hello'}, c:diff(nil):all())
end

function _M:testDiffKeys()

    local c1 = newCol({id = 1, first_word = 'Hello'})
    local c2 = newCol({id = 123, foo_bar = 'Hello'})
    self:assertEquals({first_word = 'Hello'}, c1:diffKeys(c2):all())
end

function _M:testEach()

    local original = {1, 2, foo = 'bar', bam = 'baz'}
    local c = newCol(original)
    local result = {}
    c:each(function(item, key)
        result[key] = item
    end)
    self:assertEquals(original, result)
    result = {}
    c:each(function(item, key)
        result[key] = item
        if lf.isStr(key) then
            
            return false
        end
    end)
    self:assertEquals({1, 2, foo = 'bar'}, result)
end

function _M:testIntersectNull()

    local c = newCol({id = 1, first_word = 'Hello'})
    self:assertEquals({}, c:intersect(nil):all())
end

function _M:testIntersectCollection()

    local c = newCol({id = 1, first_word = 'Hello'})
    self:assertEquals({first_word = 'Hello'}, c:intersect(newCol({first_world = 'Hello', last_word = 'World'})):all())
end

function _M:testUnique()

    local c = newCol({'Hello', 'World', 'World'})
    self:assertEquals({'Hello', 'World'}, c:unique():all())
end

function _M:testUniqueWithCallback()

    local c = newCol({
        {id = 1, first = 'Taylor', last = 'Otwell'},
        {id = 2, first = 'Taylor', last = 'Otwell'},
        {id = 3, first = 'Abigail', last = 'Otwell'},
        {id = 4, first = 'Abigail', last = 'Otwell'},
        {id = 5, first = 'Taylor', last = 'Swift'},
        {id = 6, first = 'Taylor', last = 'Swift'}
    })

    self:assertEquals({{id = 1, first = 'Taylor', last = 'Otwell'}, {id = 3, first = 'Abigail', last = 'Otwell'}}, c:unique('first'):all())
    self:assertEquals({{id = 1, first = 'Taylor', last = 'Otwell'}, {id = 3, first = 'Abigail', last = 'Otwell'}, {id = 5, first = 'Taylor', last = 'Swift'}}, c:unique(function(item)
        
        return item.first .. item.last
    end):all())
    self:assertEquals({{id = 1, first = 'Taylor', last = 'Otwell'}, {id = 2, first = 'Taylor', last = 'Otwell'}}, c:unique(function(item, key)

        return key % 2
    end):all())
end

function _M:testCollapseWithNestedCollactions()

    local data = newCol({newCol({1, 2, 3}), newCol({4, 5, 6})})
    self:assertEquals({1, 2, 3, 4, 5, 6}, data:collapse():all())
end

function _M:testSort()

    local data = (newCol({5, 3, 1, 2, 4})):sort()
    self:assertEquals({1, 2, 3, 4, 5}, data:values():all())
    data = (newCol({-1, -3, -2, -4, -5, 0, 5, 3, 1, 2, 4})):sort()
    self:assertEquals({-5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5}, data:values():all())
    data = (newCol({'foo', 'bar-10', 'bar-1'})):sort()
    self:assertEquals({'bar-1', 'bar-10', 'foo'}, data:values():all())
end

function _M:testSortWithCallback()

    local data = (newCol({5, 3, 1, 2, 4})):sort(function(a, b)
        if a == b then
            
            return 0
        end
        
        return a < b and -1 or 1
    end)
    self:assertEquals(tb.range(1, 5), tb.values(data:all()))
end

function _M:testSortBy()

    local data = newCol({'taylor', 'dayle'})
    data = data:sortBy(function(x)
        
        return x
    end)

    self:assertEquals({'dayle', 'taylor'}, tb.values(data:all()))
    data = newCol({'dayle', 'taylor'})
    data = data:sortByDesc(function(x)
        
        return x
    end)
    self:assertEquals({'taylor', 'dayle'}, tb.values(data:all()))
end

function _M:testSortByString()

    local data = newCol({{name = 'taylor'}, {name = 'dayle'}})
    data = data:sortBy('name')
    self:assertEquals({{name = 'dayle'}, {name = 'taylor'}}, tb.values(data:all()))
end

function _M:testSortByAlwaysReturnsAssoc()

    local data = newCol({a = 'taylor', b = 'dayle'})
    data = data:sortBy(function(x)
        
        return x
    end)
    self:assertEquals({b = 'dayle', a = 'taylor'}, data:all())
end

function _M:testReverse()

    local data = newCol({'zaeed', 'alan'})
    local reversed = data:reverse()
    self:assertSame({'alan', 'zaeed'}, reversed:all())
    data = newCol({name = 'taylor', framework = 'laravel'})
    reversed = data:reverse()
    self:assertSame({framework = 'laravel', name = 'taylor'}, reversed:all())
end

function _M:testFlip()

    local data = newCol({name = 'taylor', framework = 'laravel'})
    self:assertEquals({taylor = 'name', laravel = 'framework'}, data:flip():toArr())
end

function _M:testChunk()

    local data = newCol({1, 2, 3, 4, 5, 6, 7, 8, 9, 10})
    data = data:chunk(3)
    self:assertCount(4, data)
    self:assertEquals({1, 2, 3}, data(1))
    self:assertEquals({10}, data(4))
end

function _M:testChunkWhenGivenZeroAsSize()

    local collection = newCol({1, 2, 3, 4, 5, 6, 7, 8, 9, 10})
    self:assertEquals({}, collection:chunk(0):toArr())
end

function _M:testChunkWhenGivenLessThanZero()

    local collection = newCol({1, 2, 3, 4, 5, 6, 7, 8, 9, 10})
    self:assertEquals({}, collection:chunk(-1):toArr())
end

function _M:testEvery()

    local c = newCol({})
    self:assertTrue(c:every('key', 'value'))
    self:assertTrue(c:every(function()
        
        return false
    end))
    c = newCol({{age = 18}, {age = 20}, {age = 20}})
    self:assertFalse(c:every('age', 18))
    self:assertTrue(c:every('age', '>=', 18))
    self:assertTrue(c:every(function(item)
        
        return item['age'] >= 18
    end))
    self:assertFalse(c:every(function(item)
        
        return item['age'] >= 20
    end))
    c = newCol({nil, nil})
    self:assertTrue(c:every(function(item)
        
        return item == nil
    end))
    c = newCol({{active = true}, {active = true}})
    self:assertTrue(c:every('active'))
end

function _M:testExcept()

    local data = newCol({first = 'Taylor', last = 'Otwell', email = 'taylorotwell@gmail.com'})
    self:assertEquals({first = 'Taylor'}, data:except({'last', 'email', 'missing'}):all())
    self:assertEquals({first = 'Taylor'}, data:except('last', 'email', 'missing'):all())
    self:assertEquals({first = 'Taylor', email = 'taylorotwell@gmail.com'}, data:except({'last'}):all())
    self:assertEquals({first = 'Taylor', email = 'taylorotwell@gmail.com'}, data:except('last'):all())
end

function _M:testPluckWithArrayAndObjectValues()

    local data = newCol({{name = 'taylor', email = 'foo'}, {name = 'dayle', email = 'bar'}})
    self:assertEquals({taylor = 'foo', dayle = 'bar'}, data:pluck('email', 'name'):all())
    self:assertEquals({'foo', 'bar'}, data:pluck('email'):all())
end

function _M:testImplode()

    local data = newCol({{name = 'taylor', email = 'foo'}, {name = 'dayle', email = 'bar'}})
    self:assertEquals('foobar', data:implode('email'))
    self:assertEquals('foo,bar', data:implode('email', ','))
    data = newCol({'taylor', 'dayle'})
    self:assertEquals('taylordayle', data:implode(''))
    self:assertEquals('taylor,dayle', data:implode(','))
end

function _M:testTake()

    local data = newCol({'taylor', 'dayle', 'shawn'})
    data = data:take(2)
    self:assertEquals({'taylor', 'dayle'}, data:all())
end

function _M:testRandom()

    local data = newCol({1, 2, 3, 4, 5, 6})
    local random = data:random(1)
    self:assertInternalType('integer', random)
    random = data:random(3)
    self:assertCount(3, random)
end

function _M:testRandomWithoutArgument()

    local data = newCol({1, 2, 3, 4, 5, 6})
    local random = data:random()

    self:assertInternalType('integer', random)
    self:assertContains(random, data:all())
end

-- @expectedException InvalidArgumentException

function _M:testRandomThrowsAnErrorWhenRequestingMoreItemsThanAreAvailable()

    (newCol()):random()
end

function _M:testTakeLast()

    local data = newCol({'taylor', 'dayle', 'shawn'})
    data = data:take(-2)
    self:assertEquals({[1] = 'dayle', [2] = 'shawn'}, data:all())
end

function _M:testMakeMethod()

    local collection = localCol:make('foo')
    self:assertEquals({'foo'}, collection:all())
end

function _M:testMakeMethodFromNull()

    local collection = localCol:make(nil)
    self:assertEquals({}, collection:all())
    collection = localCol:make()
    self:assertEquals({}, collection:all())
end

function _M:testMakeMethodFromCollection()

    local firstCollection = localCol:make({foo = 'bar'})
    local secondCollection = localCol:make(firstCollection)
    self:assertEquals({foo = 'bar'}, secondCollection:all())
end

function _M:testMakeMethodFromArray()

    local collection = localCol:make({foo = 'bar'})
    self:assertEquals({foo = 'bar'}, collection:all())
end

function _M:testTimesMethod()

    local two = localCol:times(2, function(number)
        
        return 'slug-' .. number
    end)
    local zero = localCol:times(0, function(number)
        
        return 'slug-' .. number
    end)
    local negative = localCol:times(-4, function(number)
        
        return 'slug-' .. number
    end)
    local range = localCol:times(5)

    self:assertEquals({'slug-1', 'slug-2'}, two:all())
    self:assertTrue(zero:isEmpty())
    self:assertTrue(negative:isEmpty())
    self:assertEquals(tb.range(1, 5), range:all())
end

function _M:testConstructMethodFromNull()

    local collection = newCol(nil)
    self:assertEquals({}, collection:all())
    collection = newCol()
    self:assertEquals({}, collection:all())
end

function _M:testConstructMethodFromArray()

    local collection = newCol({foo = 'bar'})
    self:assertEquals({foo = 'bar'}, collection:all())
end

function _M:testSplice()

    local data = newCol({'foo', 'baz'})
    data:splice(2)
    self:assertEquals({'foo'}, data:all())
    data = newCol({'foo', 'baz'})
    data:splice(2, 0, 'bar')
    self:assertEquals({'foo', 'bar', 'baz'}, data:all())
    data = newCol({'foo', 'baz'})
    data:splice(2, 1)
    self:assertEquals({'foo'}, data:all())
    data = newCol({'foo', 'baz'})
    local cut = data:splice(2, 1, 'bar')
    self:assertEquals({'foo', 'bar'}, data:all())

    self:assertEquals({'baz'}, cut:all())
end

function _M:testMapSpread()

    local c = newCol({{1, 'a'}, {2, 'b'}})
    local result = c:mapSpread(function(number, character)
        
        return number .. '-' .. character
    end)
    self:assertEquals({'1-a', '2-b'}, result:all())
end

function _M:testFlatMap()

    local data = newCol({
        {name = 'taylor', hobbies = {'programming', 'basketball'}},
        {name = 'adam', hobbies = {'music', 'powerlifting'}}
    })
    data = data:flatMap(function(person)
        
        return person.hobbies
    end)
    self:assertEquals({'programming', 'basketball', 'music', 'powerlifting'}, data:all())
end

function _M:testMapToGroups()

    local data = newCol({
        {id = 1, name = 'A'},
        {id = 2, name = 'B'},
        {id = 3, name = 'C'},
        {id = 4, name = 'B'}
    })
    local groups = data:mapToGroups(function(item, key)
        
        return {[item.name] = item.id}
    end)
    self:assertInstanceOf('col', groups)
    self:assertEquals({A = {1}, B = {2, 4}, C = {3}}, groups:toArr())
end

function _M:testMapToGroupsWithNumericKeys()

    local data = newCol({1, 2, 3, 2, 1})
    local groups = data:mapToGroups(function(item, key)
        
        return {[item] = key}
    end)
    self:assertEquals({
        {1, 5}, {2, 4}, {3}
    }, groups:toArr())
end

function _M:testMapWithKeys()

    local data = newCol({{name = 'Blastoise', type = 'Water', idx = 9}, {name = 'Charmander', type = 'Fire', idx = 4}, {name = 'Dragonair', type = 'Dragon', idx = 148}})
    data = data:mapWithKeys(function(pokemon)
        
        return {[pokemon.name] = pokemon.type}
    end)

    self:assertEquals({Blastoise = 'Water', Charmander = 'Fire', Dragonair = 'Dragon'}, data:all())
end

function _M:testMapWithKeysIntegerKeys()

    local data = newCol({{id = 1, name = 'A'}, {id = 3, name = 'B'}, {id = 2, name = 'C'}})
    data = data:mapWithKeys(function(item)
        
        return {[item.name] = item}
    end)
    self:assertSame({'A', 'B', 'C'}, data:keys():sort():all())
end

function _M:testMapWithKeysMultipleRows()

    local data = newCol({{id = 1, name = 'A'}, {id = 2, name = 'B'}, {id = 3, name = 'C'}})
    data = data:mapWithKeys(function(item)
        
        return {[item.id] = item.name, [item.name] = item.id}
    end)
    self:assertSame({
        [1] = 'A',
        A = 1,
        [2] = 'B',
        B = 2,
        [3] = 'C',
        C = 3
    }, data:all())
end

function _M:testMapWithKeysCallbackKey()

    local data = newCol({[3] = {id = 1, name = 'A'}, [5] = {id = 3, name = 'B'}, [4] = {id = 2, name = 'C'}})
    data = data:mapWithKeys(function(item, key)
        return {[key] = item.id}
    end)

    self:assertEquals({'3', '4', '5'}, data:sort():keys():all())
end

function _M:testNth()

    local data = newCol({'a', 'b', 'c', 'd', 'e','f'})
    self:assertEquals({'a', 'e'}, data:nth(4):all())
    self:assertEquals({'b', 'f'}, data:nth(4, 1):all())
    self:assertEquals({'c'}, data:nth(4, 2):all())
    self:assertEquals({'d'}, data:nth(4, 3):all())
end

function _M:testTransform()

    local data = newCol({first = 'taylor', last = 'otwell'})
    data:transform(function(item, key)
        return key .. '-' .. str.rev(item)
    end)

    self:assertEquals(
        {first = 'first-rolyat', last = 'last-llewto'}, data:all()
    )
end

function _M:testGroupByAttribute()

    local data = newCol({{rating = 1, url = '1'}, {rating = 1, url = '1'}, {rating = 2, url = '2'}})
    local result = data:groupBy('rating')

    self:assertEquals({
        {{rating = 1, url = '1'}, {rating = 1, url = '1'}},
        {{rating = 2, url = '2'}}}, result:toArr())
    result = data:groupBy('url')

    self:assertEquals({
        ['1'] = {{rating = 1, url = '1'}, {rating = 1, url = '1'}},
        ['2'] = {{rating = 2, url = '2'}}}, result:toArr())
end

function _M:testGroupByAttributePreservingKeys()

    local data = newCol({[10] = {rating = 1, url = '1'}, [20] = {rating = 1, url = '1'}, [30] = {rating = 2, url = '2'}})
    local result = data:groupBy('rating', true)

    local expected_result = {
        [1] = {['10'] = {rating = 1, url = '1'}, ['20'] = {rating = 1, url = '1'}},
        [2] = {['30'] = {rating = 2, url = '2'}}
    }

    self:assertEquals(expected_result, result:toArr())
end

function _M:testGroupByClosureWhereItemsHaveSingleGroup()

    local data = newCol({{rating = 1, url = '1'}, {rating = 1, url = '1'}, {rating = 2, url = '2'}})
    local result = data:groupBy(function(item)
        
        return item['rating']
    end)
    self:assertEquals({[1] = {{rating = 1, url = '1'}, {rating = 1, url = '1'}}, [2] = {{rating = 2, url = '2'}}}, result:toArr())
end

function _M:testGroupByClosureWhereItemsHaveSingleGroupPreservingKeys()

    local data = newCol({
        [10] = {rating = 1, url = '1'}, 
        [20] = {rating = 1, url = '1'}, 
        [30] = {rating = 2, url = '2'}
    })
    local result = data:groupBy(function(item)
        
        return item.rating
    end, true)

    local expected_result = {
        [1] = {
            ['10'] = {rating = 1, url = '1'}, 
            ['20'] = {rating = 1, url = '1'}
        },
        [2] = {
            ['30'] = {rating = 2, url = '2'}
        }
    }
    self:assertEquals(expected_result, result:toArr())
end

function _M:testGroupByClosureWhereItemsHaveMultipleGroups()

    local data = newCol({{user = 1, roles = {'Role_1', 'Role_3'}}, {user = 2, roles = {'Role_1', 'Role_2'}}, {user = 3, roles = {'Role_1'}}})
    local result = data:groupBy(function(item)
        
        return item['roles']
    end)
    local expected_result = {Role_1 = {{user = 1, roles = {'Role_1', 'Role_3'}}, {user = 2, roles = {'Role_1', 'Role_2'}}, {user = 3, roles = {'Role_1'}}}, Role_2 = {{user = 2, roles = {'Role_1', 'Role_2'}}}, Role_3 = {{user = 1, roles = {'Role_1', 'Role_3'}}}}
    self:assertEquals(expected_result, result:toArr())
end

function _M:testGroupByClosureWhereItemsHaveMultipleGroupsPreservingKeys()

    local data = newCol({
        [10] = {user = 1, roles = {'Role_1', 'Role_3'}},
        [20] = {user = 2, roles = {'Role_1', 'Role_2'}},
        [30] = {user = 3, roles = {'Role_1'}}})
    local result = data:groupBy(function(item)
        return item['roles']
    end, true)
    local expected_result = {
        Role_1 = {
            ['10'] = {user = 1, roles = {'Role_1', 'Role_3'}},
            ['20'] = {user = 2, roles = {'Role_1', 'Role_2'}},
            ['30'] = {user = 3, roles = {'Role_1'}}
        },
        Role_2 = {
            ['20'] = {user = 2, roles = {'Role_1', 'Role_2'}}
        },
        Role_3 = {
            ['10'] = {user = 1, roles = {'Role_1', 'Role_3'}}
        }
    }
    self:assertEquals(expected_result, result:toArr())
end

function _M:testKeyByAttribute()

    local data = newCol({{rating = 1, name = '1'}, {rating = 2, name = '2'}, {rating = 3, name = '3'}})
    local result = data:keyBy('rating')
    self:assertEquals({
        ['1'] = {rating = 1, name = '1'}, 
        ['2'] = {rating = 2, name = '2'}, 
        ['3'] = {rating = 3, name = '3'}
    }, result:all())
    result = data:keyBy(function(item)
        
        return item['rating'] * 2
    end)
    self:assertEquals({
        ['2'] = {rating = 1, name = '1'},
        ['4'] = {rating = 2, name = '2'}, 
        ['6'] = {rating = 3, name = '3'}
    }, result:all())
end

function _M:testKeyByClosure()

    local data = newCol({
        {firstname = 'Taylor', lastname = 'Otwell', locale = 'US'},
        {firstname = 'Lucas', lastname = 'Michot', locale = 'FR'}
    })
    local result = data:keyBy(function(item, key)
        
        return str.lower(key .. '-' .. item.firstname .. item.lastname)
    end)

    self:assertEquals({
            ['1-taylorotwell'] = {firstname = 'Taylor', lastname = 'Otwell', locale = 'US'},
            ['2-lucasmichot'] = {firstname = 'Lucas', lastname = 'Michot', locale = 'FR'}
        },
        result:all()
    )
end

function _M:testContains()

    local c = newCol({1, 3, 5})
    self:assertTrue(c:contains(1))
    self:assertFalse(c:contains(2))
    self:assertTrue(c:contains(function(value)
        
        return value < 5
    end))
    self:assertFalse(c:contains(function(value)
        
        return value > 5
    end))
    c = newCol({{v = 1}, {v = 3}, {v = 5}})
    self:assertTrue(c:contains('v', 1))
    self:assertFalse(c:contains('v', 2))
    c = newCol({'date', 'class', {foo = 50}})
    self:assertTrue(c:contains('date'))
    self:assertTrue(c:contains('class'))
    self:assertFalse(c:contains('foo'))
end

function _M:testContainsStrict()

    local c = newCol({1, 3, 5, '02'})
    self:assertTrue(c:containsStrict(1))
    self:assertFalse(c:containsStrict(2))
    self:assertTrue(c:containsStrict('02'))
    self:assertTrue(c:containsStrict(function(value)
        
        return lf.isNum(value) and value < 5
    end))
    self:assertFalse(c:containsStrict(function(value)
        
        return lf.isNum(value) and value > 5
    end))
    c = newCol({{v = 1}, {v = 3}, {v = '04'}, {v = 5}})
    self:assertTrue(c:containsStrict('v', 1))
    self:assertFalse(c:containsStrict('v', 2))
    self:assertFalse(c:containsStrict('v', 4))
    self:assertTrue(c:containsStrict('v', '04'))
    c = newCol({'date', 'class', {foo = 50}, ''})
    self:assertTrue(c:containsStrict('date'))
    self:assertTrue(c:containsStrict('class'))
    self:assertFalse(c:containsStrict('foo'))
    self:assertFalse(c:containsStrict(nil))
    self:assertTrue(c:containsStrict(''))
end

function _M:testContainsWithOperator()

    local c = newCol({{v = 1}, {v = 3}, {v = '4'}, {v = 5}})
    self:assertTrue(c:contains('v', '=', 4))
    self:assertTrue(c:contains('v', '==', 4))
    self:assertFalse(c:contains('v', '===', 4))
    self:assertTrue(c:contains('v', '>', 4))
end

function _M:testGettingSumFromCollection()

    local c = newCol({{foo = 50}, {foo = 50}})
    self:assertEquals(100, c:sum('foo'))
    c = newCol({{foo = 50}, {foo = 50}})
    self:assertEquals(100, c:sum(function(i)
        
        return i.foo
    end))
end

function _M:testCanSumValuesWithoutACallback()

    local c = newCol({1, 2, 3, 4, 5})
    self:assertEquals(15, c:sum())
end

function _M:testGettingSumFromEmptyCollection()

    local c = newCol()
    self:assertEquals(0, c:sum('foo'))
end

function _M:testValueRetrieverAcceptsDotNotation()

    local c = newCol({{id = 1, foo = {bar = 'B'}}, {id = 2, foo = {bar = 'A'}}})
    c = c:sortBy('foo.bar')
    self:assertEquals({2, 1}, c:pluck('id'):all())
end

function _M:testPullRetrievesItemFromCollection()

    local c = newCol({'foo', 'bar'})
    self:assertEquals('foo', c:pull(1))
end

function _M:testPullRemovesItemFromCollection()

    local c = newCol({'foo', 'bar'})
    c:pull(1)

    self:assertEquals({'bar'}, c:all())
end

function _M:testPullReturnsDefault()

    local c = newCol({})
    local value = c:pull(0, 'foo')
    self:assertEquals('foo', value)
end

function _M:testRejectRemovesElementsPassingTruthTest()

    local c = newCol({'foo', 'bar'})

    self:assertEquals({'foo'}, c:reject('bar'):values():all())
    c = newCol({'foo', 'bar'})
    self:assertEquals({'foo'}, c:reject(function(v)
        
        return v == 'bar'
    end):values():all())
    c = newCol({'foo', nil})
    self:assertEquals({'foo'}, c:reject(nil):values():all())
    c = newCol({'foo', 'bar'})
    self:assertEquals({'foo', 'bar'}, c:reject('baz'):values():all())
    c = newCol({'foo', 'bar'})
    self:assertEquals({'foo', 'bar'}, c:reject(function(v)
        
        return v == 'baz'
    end):values():all())
    c = newCol({id = 1, primary = 'foo', secondary = 'bar'})
    self:assertEquals({primary = 'foo', secondary = 'bar'}, c:reject(function(item, key)
        
        return key == 'id'
    end):all())
end

function _M:testSearchReturnsIndexOfFirstFoundItem()

    local c = newCol({6, 5, 4, 3, 2})
    self:assertEquals(5, c:search(2))
    self:assertEquals(1, c:search(function(value)
        
        return value > 4
    end))
end

function _M:testSearchReturnsFalseWhenItemIsNotFound()

    local c = newCol({})
    c:add(1):add(3):add(6):add('foo')
    self:assertFalse(c:search(2))
    self:assertFalse(c:search('bar'))
    self:assertFalse(c:search(function(value)
        
        return lf.isNum(value) and value > 8
    end))
    self:assertFalse(c:search(function(value)
        
        return value == 'nope'
    end))
end

function _M:testKeys()

    local c = newCol({name = 'taylor', framework = 'laravel'})
    self:assertEquals({'name', 'framework'}, c:keys():all())
end

function _M:testPaginate()

    local c = newCol({'one', 'two', 'three', 'four'})
    self:assertEquals({'one', 'two'}, c:forPage(1, 2):all())
    self:assertEquals({'three', 'four'}, c:forPage(2, 2):all())
    self:assertEquals({}, c:forPage(3, 2):all())
end

function _M:testPrepend()

    local c = newCol({'one', 'two', 'three', 'four'})
    self:assertEquals({'zero', 'one', 'two', 'three', 'four'}, c:prepend('zero'):all())
    c = newCol({one = 1, two = 2})
    self:assertEquals({zero = 0, one = 1, two = 2}, c:prepend(0, 'zero'):all())
end

function _M:testZip()

    local c = newCol({1, 2, 3})
    c = c:zip(newCol({4, 5, 6}))

    self:assertInstanceOf('col', c)
    self:assertCount(3, c)
    self:assertEquals({1, 4}, c(1))
    self:assertEquals({2, 5}, c(2))
    self:assertEquals({3, 6}, c(3))
    c = newCol({1, 2, 3})
    c = c:zip({4, 5, 6}, {7, 8, 9})
    self:assertCount(3, c)
    self:assertEquals({1, 4, 7}, c(1))
    self:assertEquals({2, 5, 8}, c(2))
    self:assertEquals({3, 6, 9}, c(3))
    c = newCol({1, 2, 3})
    c = c:zip({4, 5, 6}, {7})
    self:assertCount(3, c)
    self:assertEquals({1, 4, 7}, c(1))
    self:assertEquals({2, 5, nil}, c(2))
    self:assertEquals({3, 6, nil}, c(3))
end

function _M:testGettingMaxItemsFromCollection()

    local c = newCol({{foo = 10}, {foo = 20}})
    self:assertEquals(20, c:max(function(item)
        
        return item.foo
    end))
    self:assertEquals(20, c:max('foo'))
    c = newCol({{foo = 10}, {foo = 20}})
    self:assertEquals(20, c:max('foo'))
    c = newCol({1, 2, 3, 4, 5})
    self:assertEquals(5, c:max())
    c = newCol()
    self:assertNull(c:max())
end

function _M:testGettingMinItemsFromCollection()

    local c = newCol({{foo = 10}, {foo = 20}})
    self:assertEquals(10, c:min(function(item)
        
        return item.foo
    end))
    self:assertEquals(10, c:min('foo'))
    c = newCol({{foo = 10}, {foo = 20}})
    self:assertEquals(10, c:min('foo'))
    c = newCol({1, 2, 3, 4, 5})
    self:assertEquals(1, c:min())
    c = newCol({1, nil, 3, 4, 5})
    self:assertEquals(1, c:min())
    c = newCol({0, 1, 2, 3, 4})
    self:assertEquals(0, c:min())
    c = newCol()
    self:assertNull(c:min())
end

function _M:testOnly()

    local data = newCol({first = 'Taylor', last = 'Otwell', email = 'taylorotwell@gmail.com'})
    self:assertEquals(data:all(), data:only(nil):all())
    self:assertEquals({first = 'Taylor'}, data:only({'first', 'missing'}):all())
    self:assertEquals({first = 'Taylor'}, data:only('first', 'missing'):all())
    self:assertEquals({first = 'Taylor', email = 'taylorotwell@gmail.com'}, data:only({'first', 'email'}):all())
    self:assertEquals({first = 'Taylor', email = 'taylorotwell@gmail.com'}, data:only('first', 'email'):all())
end

function _M:testGettingAvgItemsFromCollection()

    local c = newCol({{foo = 10}, {foo = 20}})
    self:assertEquals(15, c:avg(function(item)
        
        return item.foo
    end))
    self:assertEquals(15, c:avg('foo'))
    c = newCol({{foo = 10}, {foo = 20}})
    self:assertEquals(15, c:avg('foo'))
    c = newCol({1, 2, 3, 4, 5})
    self:assertEquals(3, c:avg())
    c = newCol()
    self:assertNull(c:avg())
end

function _M:testCombineWithArray()

    local expected = {[1] = 4, [2] = 5, [3] = 6}
    local c = newCol(tb.keys(expected))
    local actual = c:combine(tb.values(expected)):toArr()
    self:assertSame(expected, actual)
end

function _M:testCombineWithCollection()

    local expected = {[1] = 4, [2] = 5, [3] = 6}
    local keyCollection = newCol(tb.keys(expected))
    local valueCollection = newCol(tb.values(expected))
    local actual = keyCollection:combine(valueCollection):toArr()
    self:assertSame(expected, actual)
end

function _M:testReduce()

    local data = newCol({1, 2, 3})
    self:assertEquals(6, data:reduce(function(carry, element)
        carry = carry + element
        return carry
    end, 0))
end

-- @expectedException InvalidArgumentException

function _M:testRandomThrowsAnExceptionUsingAmountBiggerThanCollectionSize()

    local data = newCol({1, 2, 3})
    data:random(4)
end

function _M:testPipe()

    local collection = newCol({1, 2, 3})
    self:assertEquals(6, collection:pipe(function(collection)
        
        return collection:sum()
    end))
end

function _M:testModeOnNullCollection()

    local collection = newCol()
    self:assertNull(collection:mode())
end

function _M:testMode()

    local collection = newCol({1, 2, 3, 4, 4, 5})

    self:assertEquals({4}, collection:mode())
end

function _M:testModeValueByKey()

    local collection = newCol({{foo = 1}, {foo = 1}, {foo = 2}, {foo = 4}})

    self:assertEquals({1}, collection:mode('foo'))
end

function _M:testWithMultipleModeValues()

    local collection = newCol({1, 2, 2, 1})
    self:assertEquals({1, 2}, collection:mode())
end

function _M:testSplitCollectionWithADivisableCount()

    local collection = newCol({'a', 'b', 'c', 'd'})
    self:assertEquals({{'a', 'b'}, {'c', 'd'}}, collection:split(2):map(function(chunk)
        
        return chunk
    end):toArr())
end

function _M:testSplitCollectionWithAnUndivisableCount()

    local collection = newCol({'a', 'b', 'c'})
    self:assertEquals({{'a', 'b'}, {'c'}}, collection:split(2):map(function(chunk)
        
        return chunk
    end):toArr())
end

function _M:testSplitEmptyCollection()

    local collection = newCol()
    self:assertEquals({}, collection:split(2):map(function(chunk)
        
        return chunk:values():toArr()
    end):toArr())
end

function _M:testPartition()

    local collection = newCol(tb.range(1, 10))
    local firstPartition, secondPartition = unpack(collection:partition(function(i)
        
        return i <= 5
    end):all())
    self:assertEquals({1, 2, 3, 4, 5}, firstPartition)
    self:assertEquals({6, 7, 8, 9, 10}, secondPartition)
end

function _M:testPartitionByKey()

    local courses = newCol({{free = true, title = 'Basic'}, {free = false, title = 'Premium'}})
    local free, premium = unpack(courses:partition('free'):all())
    self:assertEquals({{free = true, title = 'Basic'}}, free)
    self:assertEquals({{free = false, title = 'Premium'}}, premium)
end

function _M:testPartitionPreservesKeys()

    local courses = newCol({a = {free = true}, b = {free = false}, c = {free = true}})
    local free, premium = unpack(courses:partition('free'):all())
    self:assertSame({a = {free = true}, c = {free = true}}, free)
    self:assertSame({b = {free = false}}, premium)
end

function _M:testPartitionEmptyCollection()

    local collection = newCol()
    self:assertCount(2, collection:partition(function()
        
        return true
    end))
end

function _M:testTap()

    local collection = newCol({1, 2, 3})
    local fromTap = {}
    collection = collection:tap(function(collection)
        fromTap = collection:slice(1, 1):toArr()
    end)
    self:assertSame({1}, fromTap)
    self:assertSame({1, 2, 3}, collection:toArr())
end

function _M:testWhen()

    local collection = newCol({'michael', 'tom'})
    collection:when(true, function(collection)
        
        return collection:push('adam')
    end)
    self:assertSame({'michael', 'tom', 'adam'}, collection:toArr())
    collection = newCol({'michael', 'tom'})
    collection:when(false, function(collection)
        
        return collection:push('adam')
    end)
    self:assertSame({'michael', 'tom'}, collection:toArr())
end

function _M:testWhenDefault()

    local collection = newCol({'michael', 'tom'})
    collection:when(false, function(collection)
        
        return collection:push('adam')
    end, function(collection)
        
        return collection:push('taylor')
    end)
    self:assertSame({'michael', 'tom', 'taylor'}, collection:toArr())
end

function _M:testSliceOffset()

    local collection = newCol({1, 2, 3, 4, 5, 6, 7, 8})
    self:assertEquals({4, 5, 6, 7, 8}, collection:slice(4):values():toArr())
end

function _M:testSliceNegativeOffset()

    local collection = newCol({1, 2, 3, 4, 5, 6, 7, 8})
    self:assertEquals({6, 7, 8}, collection:slice(-3):values():toArr())
end

function _M:testSliceOffsetAndLength()

    local collection = newCol({1, 2, 3, 4, 5, 6, 7, 8})

    self:assertEquals({4, 5, 6}, collection:slice(4, 3):values():toArr())
end

function _M:testSliceOffsetAndNegativeLength()

    local collection = newCol({1, 2, 3, 4, 5, 6, 7, 8})

    self:assertEquals({4, 5, 6, 7}, collection:slice(4, -1):values():toArr())
end

function _M:testSliceNegativeOffsetAndLength()

    local collection = newCol({1, 2, 3, 4, 5, 6, 7, 8})
    self:assertEquals({4, 5, 6}, collection:slice(-5, 3):values():toArr())
end

function _M:testSliceNegativeOffsetAndNegativeLength()

    local collection = newCol({1, 2, 3, 4, 5, 6, 7, 8})
    self:assertEquals({3, 4, 5, 6}, collection:slice(-6, -2):values():toArr())
end

function _M:testMap()

    local data = newCol({first = 'taylor', last = 'otwell'})
    data = data:map(function(item, key)
        
        return key .. '-' .. str.rev(item)
    end)
    self:assertEquals({first = 'first-rolyat', last = 'last-llewto'}, data:all())
end

return _M

