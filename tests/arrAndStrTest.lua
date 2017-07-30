
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'unit.testCase'
}

local app, lf, tb, str = lx.kit()
local clone = tb.clone

function _M:tearDown()

    self:close()
end

function _M:testArrayDot()

    local array = tb.dot({name = 'taylor', languages = {php = true}})
    self:assertEquals(array, {name = 'taylor', ['languages.php'] = true})
end

function _M:testArrayGet()

    local array = {names = {developer = 'taylor'}}
    self:assertEquals('taylor', tb.get(array, 'names.developer'))
    self:assertEquals('dayle', tb.get(array, 'names.otherDeveloper', 'dayle'))
    self:assertEquals('dayle', tb.get(array, 'names.otherDeveloper', function()
        
            return 'dayle'
    end))
end

function _M:testArrayHas()

    local array = {names = {developer = 'taylor'}}
    self:assertTrue(tb.has(array, 'names'))
    self:assertTrue(tb.has(array, 'names.developer'))
    self:assertFalse(tb.has(array, 'foo'))
    self:assertFalse(tb.has(array, 'foo.bar'))
end

function _M:testArraySet()

    local array = {}
    tb.set(array, 'names.developer', 'taylor')
    self:assertEquals('taylor', array['names']['developer'])
end

function _M:testArrayForget()

    local array = {names = {developer = 'taylor', otherDeveloper = 'dayle'}}
    tb.forget(array, 'names.developer')
    self:assertFalse(array['names']['developer'])
    self:assertTrue(array['names']['otherDeveloper'])
    array = {names = {developer = 'taylor', otherDeveloper = 'dayle', thirdDeveloper = 'Lucas'}}
    tb.forget(array, {'names.developer', 'names.otherDeveloper'})
    self:assertFalse(array['names']['developer'])
    self:assertFalse(array['names']['otherDeveloper'])
    self:assertTrue(array['names']['thirdDeveloper'])
    array = {names = {developer = 'taylor', otherDeveloper = 'dayle'}, otherNames = {developer = 'Lucas', otherDeveloper = 'Graham'}}
    tb.forget(array, {'names.developer', 'otherNames.otherDeveloper'})
    local expected = {names = {otherDeveloper = 'dayle'}, otherNames = {developer = 'Lucas'}}
    self:assertEquals(expected, array)
end

function _M:testArrayPluckWithArrayAndObjectValues()

    local array = {{name = 'taylor', email = 'foo'}, {name = 'dayle', email = 'bar'}}
    self:assertEquals({'taylor', 'dayle'}, tb.pluck(array, 'name'))
    self:assertEquals({taylor = 'foo', dayle = 'bar'}, tb.pluck(array, 'email', 'name'))
end

function _M:testArrayPluckWithNestedKeys()

    local array = {{user = {'taylor', 'otwell'}}, {user = {'dayle', 'rees'}}}
    self:assertEquals({'taylor', 'dayle'}, tb.pluck(array, 'user.1'))
    self:assertEquals({'taylor', 'dayle'}, tb.pluck(array, {'user', 1}))
    self:assertEquals({taylor = 'otwell', dayle = 'rees'}, tb.pluck(array, 'user.2', 'user.1'))
    self:assertEquals({taylor = 'otwell', dayle = 'rees'}, tb.pluck(array, {'user', 2}, {'user', 1}))
end

function _M:testArrayPluckWithNestedArrays()

    local array = {{account = 'a', users = {{first = 'taylor', last = 'otwell', email = 'taylorotwell@gmail.com'}}}, {account = 'b', users = {{first = 'abigail', last = 'otwell'}, {first = 'dayle', last = 'rees'}}}}
    self:assertEquals({{'taylor'}, {'abigail', 'dayle'}}, tb.pluck(array, 'users.*.first'))
    self:assertEquals({a = {'taylor'}, b = {'abigail', 'dayle'}}, tb.pluck(array, 'users.*.first', 'account'))
    self:assertEquals({{'taylorotwell@gmail.com'}, {nil, nil}}, tb.pluck(array, 'users.*.email'))
end

function _M:testArrayExcept()

    local array = {name = 'taylor', age = 26}
    self:assertEquals({age = 26}, tb.except(array, {'name'}))
    self:assertEquals({age = 26}, tb.except(array, 'name'))
    array = {name = 'taylor', framework = {language = 'PHP', name = 'Laravel'}}
    self:assertEquals({name = 'taylor'}, tb.except(array, 'framework'))
    array = {name = 'taylor', framework = {language = 'PHP', name = 'Laravel'}}
    self:assertEquals({name = 'taylor', framework = {name = 'Laravel'}}, tb.except(array, 'framework.language'))
    array = {name = 'taylor', framework = {language = 'PHP', name = 'Laravel'}}
    self:assertEquals({framework = {language = 'PHP'}}, tb.except(array, {'name', 'framework.name'}))
end

function _M:testArrayOnly()

    local array = {name = 'taylor', age = 26}
    self:assertEquals({name = 'taylor'}, tb.only(array, {'name'}))

    self:assertSame({}, tb.only(array, {'nonExistingKey'}))
end

function _M:testArrayCollapse()

    local array = {{1}, {2}, {3}, {'foo', 'bar'}, {'baz', 'boom'}}
    self:assertEquals({1, 2, 3, 'foo', 'bar', 'baz', 'boom'}, tb.collapse(array))
end

function _M:testArrayDivide()

    local array = {name = 'taylor'}
    local keys, values = tb.divide(array)
    self:assertEquals({'name'}, keys)
    self:assertEquals({'taylor'}, values)
end

function _M:testArrayFirst()

    local array = {name = 'taylor', otherDeveloper = 'dayle'}
    self:assertEquals('dayle', tb.first(array, function(value)
        
        return value == 'dayle'
    end))
end

function _M:testArrayLast()

    local array = {100, 250, 290, 320, 500, 560, 670}
    self:assertEquals(670, tb.last(array, function(value)
        
        return value > 320
    end))
end

function _M:testArrayPluck()

    local data = {['post-1'] = {comments = {tags = {'#foo', '#bar'}}}, ['post-2'] = {comments = {tags = {'#baz'}}}}
    self:assertEquals({
        {tags = {'#foo', '#bar'}},
        {tags = {'#baz'}}
    }, tb.pluck(data, 'comments'))
    self:assertEquals({{'#foo', '#bar'}, {'#baz'}}, tb.pluck(data, 'comments.tags'))
    self:assertEquals({nil, nil}, tb.pluck(data, 'foo'))
    self:assertEquals({nil, nil}, tb.pluck(data, 'foo.bar'))
end

function _M:testArrayPrepend()

    local array = tb.prepend({'one', 'two', 'three', 'four'}, 'zero')
    self:assertEquals({'zero', 'one', 'two', 'three', 'four'}, array)
    array = tb.prepend({one = 1, two = 2}, 0, 'zero')
    self:assertEquals({zero = 0, one = 1, two = 2}, array)
end

function _M:testArrayFlatten()

    self:assertEquals({'#foo', '#bar', '#baz'}, tb.flatten({{'#foo', '#bar'}, {'#baz'}}))
end

function _M:testStrIs()

    self:assertTrue(str.is('localhost.dev', '*.dev'))
    self:assertTrue(str.is('a', 'a'))
    self:assertTrue(str.is('/', '/'))
    self:assertTrue(str.is('localhost.dev', '*dev*'))
    self:assertTrue(str.is('foo?bar', 'foo?bar'))
    self:assertFalse(str.is('foobar', '*something'))
    self:assertFalse(str.is('bar', 'foo'))
    self:assertFalse(str.is('foobar', 'foo.*'))
    self:assertFalse(str.is('foobar', 'foo.ar'))
    self:assertFalse(str.is('foobar', 'foo?bar'))
    self:assertFalse(str.is('fobar', 'foo?bar'))
end

function _M:testStrRandom()

    local result = str.random(20)
    self:assertInternalType('string', result)
    self:assertEquals(20, str.len(result))
end

function _M:testStartsWith()

    self:assertTrue(str.startsWith('jason', 'jas'))
    self:assertTrue(str.startsWith('jason', {'jas'}))
    self:assertFalse(str.startsWith('jason', 'day'))
    self:assertFalse(str.startsWith('jason', {'day'}))
end

function _M:testEndsWith()

    self:assertTrue(str.endsWith('jason', 'on'))
    self:assertTrue(str.endsWith('jason', {'on'}))
    self:assertFalse(str.endsWith('jason', 'no'))
    self:assertFalse(str.endsWith('jason', {'no'}))
end

function _M:testStrContains()

    self:assertTrue(str.contains('taylor', 'ylo'))
    self:assertTrue(str.contains('taylor', {'ylo'}))
    self:assertFalse(str.contains('taylor', 'xxx'))
    self:assertFalse(str.contains('taylor', {'xxx'}))
    self:assertTrue(str.contains('taylor', {'xxx', 'taylor'}))
end

function _M:testStrFinish()

    self:assertEquals('test/string/', str.finish('test/string', '/'))
    self:assertEquals('test/string/', str.finish('test/string/', '/'))
    self:assertEquals('test/string/', str.finish('test/string//', '/'))
end

function _M:testSnakeCase()

    self:assertEquals('foo_bar', str.snake('fooBar'))
    self:assertEquals('foo_bar', str.snake('fooBar'))
    -- test cache
end

function _M:testStrLimit()

    local string = 'The PHP framework for web artisans.'
    self:assertEquals('The PHP...', str.limit(string, 7))
    self:assertEquals('The PHP', str.limit(string, 7, ''))
    self:assertEquals('The PHP framework for web artisans.', str.limit(string, 100))
end

function _M:testCamelCase()

    self:assertEquals('fooBar', str.camel('FooBar'))
    self:assertEquals('fooBar', str.camel('foo_bar'))
    self:assertEquals('fooBar', str.camel('foo_bar'))
    -- test cache
    self:assertEquals('fooBarBaz', str.camel('Foo-barBaz'))
    self:assertEquals('fooBarBaz', str.camel('foo-bar_baz'))
end

function _M:testStudlyCase()

    self:assertEquals('FooBar', str.studly('fooBar'))
    self:assertEquals('FooBar', str.studly('foo_bar'))
    self:assertEquals('FooBar', str.studly('foo_bar'))
    -- test cache
    self:assertEquals('FooBarBaz', str.studly('foo-barBaz'))
    self:assertEquals('FooBarBaz', str.studly('foo-bar_baz'))
end

function _M:testValue()

    self:assertEquals('foo', tb.getValue('foo'))
    self:assertEquals('foo', tb.getValue(function()
        
        return 'foo'
    end))
end

function _M:testDataGet()

    local object = {users = {name = {'Taylor', 'Otwell'}}}
    local array = {{users = {{name = 'Taylor'}}}}
    local dottedArray = {users = {['first.name'] = 'Taylor', ['middle.name'] = nil}}
    self:assertEquals('Taylor', tb.dataGet(array, '1.users.1.name'))
    self:assertNull(tb.dataGet(array, '1.users.4'))
    self:assertEquals('Not found', tb.dataGet(array, '1.users.4', 'Not found'))
    self:assertEquals('Not found', tb.dataGet(array, '1.users.4', function()
        
        return 'Not found'
    end))
    self:assertEquals('Taylor', tb.dataGet(dottedArray, {'users', 'first.name'}))
    self:assertNull(tb.dataGet(dottedArray, {'users', 'middle.name'}))
    self:assertEquals('Not found', tb.dataGet(dottedArray, {'users', 'last.name'}, 'Not found'))
end

function _M:testDataGetWithNestedArrays()

    local array = {{name = 'taylor', email = 'taylorotwell@gmail.com'}, {name = 'abigail'}, {name = 'dayle'}}
    self:assertEquals({'taylor', 'abigail', 'dayle'}, tb.dataGet(array, '*.name'))
    self:assertEquals({'taylorotwell@gmail.com', nil, nil}, tb.dataGet(array, '*.email', 'irrelevant'))
    array = {users = {{first = 'taylor', last = 'otwell', email = 'taylorotwell@gmail.com'}, {first = 'abigail', last = 'otwell'}, {first = 'dayle', last = 'rees'}}, posts = nil}
    self:assertEquals({'taylor', 'abigail', 'dayle'}, tb.dataGet(array, 'users.*.first'))
    self:assertEquals({'taylorotwell@gmail.com', nil, nil}, tb.dataGet(array, 'users.*.email', 'irrelevant'))
    self:assertEquals('not found', tb.dataGet(array, 'posts.*.date', 'not found'))
    self:assertNull(tb.dataGet(array, 'posts.*.date'))
end

function _M:testDataGetWithDoubleNestedArraysCollapsesResult()

    local array = {posts = {{comments = {{author = 'taylor', likes = 4}, {author = 'abigail', likes = 3}}}, {comments = {{author = 'abigail', likes = 2}, {author = 'dayle'}}}, {comments = {{author = 'dayle'}, {author = 'taylor', likes = 1}}}}}
    self:assertEquals({'taylor', 'abigail', 'abigail', 'dayle', 'dayle', 'taylor'}, tb.dataGet(array, 'posts.*.comments.*.author'))
    self:assertEquals({4, 3, 2, 1}, tb.dataGet(array, 'posts.*.comments.*.likes'))
    self:assertEquals({}, tb.dataGet(array, 'posts.*.users.*.name', 'irrelevant'))
    self:assertEquals({}, tb.dataGet(array, 'posts.*.users.*.name'))
end

function _M:testDataFill()

    local data = {foo = 'bar'}
    self:assertEquals({foo = 'bar', baz = 'boom'}, tb.dataFill(data, 'baz', 'boom'))
    self:assertEquals({foo = 'bar', baz = 'boom'}, tb.dataFill(data, 'baz', 'noop'))
    self:assertEquals({foo = {}, baz = 'boom'}, tb.dataFill(data, 'foo.*', 'noop'))
    self:assertEquals({foo = {bar = 'kaboom'}, baz = 'boom'}, tb.dataFill(data, 'foo.bar', 'kaboom'))
end

function _M:testDataFillWithStar()

    local data = {foo = 'bar'}
    self:assertEquals({foo = {}}, tb.dataFill(data, 'foo.*.bar', 'noop'))
    self:assertEquals({foo = {}, bar = {{baz = 'original'}, {}}}, tb.dataFill(data, 'bar', {{baz = 'original'}, {}}))
    self:assertEquals({foo = {}, bar = {{baz = 'original'}, {baz = 'boom'}}}, tb.dataFill(data, 'bar.*.baz', 'boom'))
    self:assertEquals({foo = {}, bar = {{baz = 'original'}, {baz = 'boom'}}}, tb.dataFill(data, 'bar.*', 'noop'))
end

function _M:testDataFillWithDoubleStar()

    local data = {posts = {{comments = {{name = 'First'}, {}}}, {comments = {{}, {name = 'Second'}}}}}
    tb.dataFill(data, 'posts.*.comments.*.name', 'Filled')
    self:assertEquals({posts = {{comments = {{name = 'First'}, {name = 'Filled'}}}, {comments = {{name = 'Filled'}, {name = 'Second'}}}}}, data)
end

function _M:testDataSet()

    local data = {foo = 'bar'}
    self:assertEquals({foo = 'bar', baz = 'boom'}, tb.dataSet(data, 'baz', 'boom'))
    self:assertEquals({foo = 'bar', baz = 'kaboom'}, tb.dataSet(data, 'baz', 'kaboom'))
    self:assertEquals({foo = {}, baz = 'kaboom'}, tb.dataSet(data, 'foo.*', 'noop'))
    self:assertEquals({foo = {bar = 'boom'}, baz = 'kaboom'}, tb.dataSet(data, 'foo.bar', 'boom'))
    self:assertEquals({foo = {bar = 'boom'}, baz = {bar = 'boom'}}, tb.dataSet(data, 'baz.bar', 'boom'))
    self:assertEquals({foo = {bar = 'boom'}, baz = {bar = {boom = {kaboom = 'boom'}}}}, tb.dataSet(data, 'baz.bar.boom.kaboom', 'boom'))
end

function _M:testDataSetWithStar()

    local data = {foo = 'bar'}
    self:assertEquals({foo = {}}, tb.dataSet(data, 'foo.*.bar', 'noop'))
    self:assertEquals({foo = {}, bar = {{baz = 'original'}, {}}}, tb.dataSet(data, 'bar', {{baz = 'original'}, {}}))
    self:assertEquals({foo = {}, bar = {{baz = 'boom'}, {baz = 'boom'}}}, tb.dataSet(data, 'bar.*.baz', 'boom'))

    self:assertEquals({foo = {}, bar = {'overwritten', 'overwritten'}}, tb.dataSet(data, 'bar.*', 'overwritten'))
end

function _M:testDataSetWithDoubleStar()

    local data = {posts = {{comments = {{name = 'First'}, {}}}, {comments = {{}, {name = 'Second'}}}}}
    tb.dataSet(data, 'posts.*.comments.*.name', 'Filled')
    self:assertEquals({posts = {{comments = {{name = 'Filled'}, {name = 'Filled'}}}, {comments = {{name = 'Filled'}, {name = 'Filled'}}}}}, data)
end

function _M:testArraySort()

    local array = {{name = 'baz'}, {name = 'foo'}, {name = 'bar'}}
    self:assertEquals({{name = 'bar'}, {name = 'baz'}, {name = 'foo'}}, tb.values(tb.sort(array, function(a, b)
        
        return a.name < b.name
    end)))
end

function _M:testArrayWhere()

    local array = {
        a = 1,
        b = 2,
        c = 3,
        d = 4,
        e = 5,
        f = 6,
        g = 7,
        h = 8
    }
    self:assertEquals({
        b = 2,
        d = 4,
        f = 6,
        h = 8
    }, tb.where(array, function(value, key)
        
        return value % 2 == 0
    end))
end

function _M:testLast()

    local array = {'a', 'b', 'c'}
    self:assertEquals('c', tb.last(array))
end

function _M:testArrayAdd()

    self:assertEquals({surname = 'Mövsümov'}, tb.add({}, 'surname', 'Mövsümov'))
    self:assertEquals({developer = {name = 'Ferid'}}, tb.add({}, 'developer.name', 'Ferid'))
end

function _M:testArrayPull()

    local developer = {firstname = 'Ferid', surname = 'Mövsümov'}
    self:assertEquals('Mövsümov', tb.pull(developer, 'surname'))
    self:assertEquals({firstname = 'Ferid'}, developer)
end

return _M

