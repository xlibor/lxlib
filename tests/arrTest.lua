
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'unit.testCase'
}

local app, lf, tb, str, new = lx.kit()

function _M:testAdd()

    local array = tb.add({name = 'Desk'}, 'price', 100)
    self:assertEquals({name = 'Desk', price = 100}, array)
end

function _M:testCollapse()

    local data = {{'foo', 'bar'}, {'baz'}}
    self:assertEquals({'foo', 'bar', 'baz'}, tb.collapse(data))
end

function _M:testDivide()

    local keys, values = tb.divide({name = 'Desk'})
    self:assertEquals({'name'}, keys)
    self:assertEquals({'Desk'}, values)
end

function _M:testDot()

    local array = tb.dot({foo = {bar = 'baz'}})
    self:assertEquals({['foo.bar'] = 'baz'}, array)

    array = tb.dot({})
    self:assertEquals({}, array)

    array = tb.dot({foo = {}})
    self:assertEquals({foo = {}}, array)

    array = tb.dot({foo = {bar = {}}})
    self:assertEquals({['foo.bar'] = {}}, array)
end

function _M:testExcept()

    local array = {name = 'Desk', price = 100}
    array = tb.except(array, {'price'})
    self:assertEquals({name = 'Desk'}, array)
end

function _M:testExists()

    self:assertTrue(tb.exists({1}, 1))
    self:assertTrue(tb.exists({false}, 1))
    self:assertTrue(tb.exists({a = 1}, 'a'))
    self:assertTrue(tb.exists({a = false}, 'a'))
    self:assertTrue(tb.exists(lx.col({a = false}), 'a'))
    self:assertFalse(tb.exists({1}, 2))
    self:assertFalse(tb.exists({nil}, 2))
    self:assertFalse(tb.exists({a = 1}, 1))
    self:assertFalse(tb.exists(lx.col({a = nil}), 'b'))
end

function _M:testFirst()

    local array = {100, 200, 300}
    local value = tb.first(array, function(value)
        
        return value >= 150
    end)
    self:assertEquals(200, value)
    self:assertEquals(100, tb.first(array))
end

function _M:testLast()

    local array = {100, 200, 300}
    local last = tb.last(array, function(value)
        
        return value < 250
    end)
    self:assertEquals(200, last)
    last = tb.last(array, function(value, key)
        
        return key < 3
    end)
    self:assertEquals(200, last)
    self:assertEquals(300, tb.last(array))
end

function _M:testFlatten()

    local array = {'#foo', '#bar', '#baz'}
    self:assertEquals({'#foo', '#bar', '#baz'},
        tb.flatten({'#foo', '#bar', '#baz'})
        , 'Flat tables are unaffected'
    )

    array = {{'#foo', '#bar'}, '#baz'}
    self:assertEquals({'#foo', '#bar', '#baz'}, tb.flatten(array),
        'Nested tables are flattened with existing flat items'
    )

    array = {{'#foo', '#bar'}, {'#baz'}}
    self:assertEquals({'#foo', '#bar', '#baz'}, tb.flatten(array),
        'Sets of nested tables are flattened'
    )

    array = {{'#foo', {'#bar'}}, {'#baz'}}
    self:assertEquals({'#foo', '#bar', '#baz'}, tb.flatten(array),
        'Deeply nested tables are flattened'
    )

    array = {lx.col({'#foo', '#bar'}), {'#baz'}}
    self:assertEquals({'#foo', '#bar', '#baz'}, tb.flatten(array),
        'Nested tables are flattened alongside tables'
    )

    array = {lx.col({'#foo', {'#bar'}}), {'#baz'}}
    self:assertEquals({'#foo', '#bar', '#baz'}, tb.flatten(array),
        'Nested tables containing plain tables are flattened'
    )

    array = {{'#foo', lx.col({'#bar'})}, {'#baz'}}
    self:assertEquals({'#foo', '#bar', '#baz'}, tb.flatten(array),
        'Nested tables containing tables are flattened'
    )

    array = {{'#foo', lx.col({'#bar', {'#zap'}})}, {'#baz'}}
    self:assertEquals({'#foo', '#bar', '#zap', '#baz'}, tb.flatten(array),
        'Nested tables containing tables containing tables are flattened'
    )

end

function _M:testFlattenWithDepth()

    -- No depth flattens recursively
    local array = {{'#foo', {'#bar', {'#baz'}}}, '#zap'}
    self:assertEquals({'#foo', '#bar', '#baz', '#zap'}, tb.flatten(array))
    -- Specifying a depth only flattens to that depth
    array = {{'#foo', {'#bar', {'#baz'}}}, '#zap'}
    self:assertEquals({'#foo', {'#bar', {'#baz'}}, '#zap'}, tb.flatten(array, 1))
    array = {{'#foo', {'#bar', {'#baz'}}}, '#zap'}
    self:assertEquals({'#foo', '#bar', {'#baz'}, '#zap'}, tb.flatten(array, 2))
end

function _M:testGet()

    local array = {['products.desk'] = {price = 100}}
    self:assertEquals({price = 100}, tb.get(array, 'products.desk'))
    array = {products = {desk = {price = 100}}}
    local value = tb.get(array, 'products.desk')
    self:assertEquals({price = 100}, value)
    -- Test null table values
    array = {foo = nil, bar = {baz = nil}}
    self:assertNull(tb.get(array, 'foo'))
    self:assertNull(tb.get(array, 'bar.baz'))

    -- Test null key returns the whole table
    array = {'foo', 'bar'}
    self:assertEquals(array, tb.get(array, nil))
    -- Test table not an table
    self:assertSame('default', tb.get(nil, 'foo', 'default'))
    self:assertSame('default', tb.get(false, 'foo', 'default'))
    -- Test table not an table and key is null
    self:assertSame('default', tb.get(nil, nil, 'default'))
    -- Test table is empty and key is null
    self:assertEquals({}, tb.get({}, nil))
    self:assertEquals({}, tb.get({}, nil, 'default'))
end

function _M:testHas()

    local array = {['products.desk'] = {price = 100}}
    self:assertTrue(tb.has(array, 'products.desk'))
    array = {products = {desk = {price = 100}}}
    self:assertTrue(tb.has(array, 'products.desk'))
    self:assertTrue(tb.has(array, 'products.desk.price'))
    self:assertFalse(tb.has(array, 'products.foo'))
    self:assertFalse(tb.has(array, 'products.desk.foo'))
    array = {foo = false, bar = {baz = false}}
    self:assertTrue(tb.has(array, 'foo'))
    self:assertTrue(tb.has(array, 'bar.baz'))
    array = {'foo', 'bar'}
    self:assertFalse(tb.has(array, nil))
    self:assertFalse(tb.has(nil, 'foo'))
    self:assertFalse(tb.has(false, 'foo'))
    self:assertFalse(tb.has(nil, nil))
    self:assertFalse(tb.has({}, nil))
    array = {products = {desk = {price = 100}}}
    self:assertTrue(tb.has(array, {'products.desk'}))
    self:assertTrue(tb.has(array, {'products.desk', 'products.desk.price'}))
    self:assertTrue(tb.has(array, {'products', 'products'}))
    self:assertFalse(tb.has(array, {'foo'}))
    self:assertFalse(tb.has(array, {}))
    self:assertFalse(tb.has(array, {'products.desk', 'products.price'}))
    self:assertFalse(tb.has({}, {nil}))
    self:assertFalse(tb.has(nil, {nil}))
end

function _M:testIsAssoc()

    self:assertTrue(tb.isAssoc({a = 'a', [1] = 'b'}))
    self:assertFalse(tb.isAssoc({[2] = 'a', [1] = 'b'}))
    self:assertTrue(tb.isAssoc({[2] = 'a', [3] = 'b'}))
    self:assertFalse(tb.isAssoc({[1] = 'a', [2] = 'b'}))
    self:assertFalse(tb.isAssoc({'a', 'b'}))
end

function _M:testOnly()

    local array = {name = 'Desk', price = 100, orders = 10}
    array = tb.only(array, {'name', 'price'})
    self:assertEquals({name = 'Desk', price = 100}, array)
end

function _M:testPluck()

    local array = {{developer = {name = 'Taylor'}}, {developer = {name = 'Abigail'}}}
    array = tb.pluck(array, 'developer.name')
    self:assertEquals({'Taylor', 'Abigail'}, array)
end

function _M:testPluckWithArrayValue()

    local array = {{developer = {name = 'Taylor'}}, {developer = {name = 'Abigail'}}}
    array = tb.pluck(array, {'developer', 'name'})

    self:assertEquals({'Taylor', 'Abigail'}, array)
end

function _M:testPluckWithKeys()

    local array = {{name = 'Taylor', role = 'developer'}, {name = 'Abigail', role = 'developer'}}
    local test1 = tb.pluck(array, 'role', 'name')
    local test2 = tb.pluck(array, nil, 'name')

    self:assertEquals({Taylor = 'developer', Abigail = 'developer'}, test1)
    self:assertEquals({Taylor = {name = 'Taylor', role = 'developer'}, Abigail = {name = 'Abigail', role = 'developer'}}, test2)
end

function _M:testPrepend()

    local array = tb.prepend({'one', 'two', 'three', 'four'}, 'zero')
    self:assertEquals({'zero', 'one', 'two', 'three', 'four'}, array)
    array = tb.prepend({one = 1, two = 2}, 0, 'zero')
    self:assertEquals({zero = 0, one = 1, two = 2}, array)
end

function _M:testPull()

    local array = {name = 'Desk', price = 100}
    local name = tb.pull(array, 'name')
    self:assertEquals('Desk', name)
    self:assertEquals({price = 100}, array)
    -- Only works on first level keys
    array = {['joe@example.com'] = 'Joe', ['jane@localhost'] = 'Jane'}
    name = tb.pull(array, 'joe@example.com')
    self:assertEquals('Joe', name)
    self:assertEquals({['jane@localhost'] = 'Jane'}, array)
    -- Does not work for nested keys
    array = {emails = {['joe@example.com'] = 'Joe', ['jane@localhost'] = 'Jane'}}
    name = tb.pull(array, 'emails.joe@example.com')
    self:assertEmpty(name)
    self:assertEquals({emails = {['joe@example.com'] = 'Joe', ['jane@localhost'] = 'Jane'}}, array)
end

function _M:testSet()

    local array = {products = {desk = {price = 100}}}
    tb.set(array, 'products.desk.price', 200)
    self:assertEquals({products = {desk = {price = 200}}}, array)
end

function _M:testSort()

    local unsorted = {{name = 'Desk'}, {name = 'Chair'}, {name = 'Box'}}
    local expected = {{name = 'Box'}, {name = 'Chair'}, {name = 'Desk'}}
    -- sort with closure
    local sortedWithClosure = tb.values(tb.sortBy(unsorted, function(value)
        
        return value.name
    end))

    self:assertEquals(expected, sortedWithClosure)
    -- sort with dot notation
    local sortedWithDotNotation = tb.values(tb.sortBy(unsorted, 'name'))
    self:assertEquals(expected, sortedWithDotNotation)
end

function _M:testWhere()

    local array = {100, '200', 300, '400', 500}
    array = tb.where(array, function(value, key)
        
        return lf.isStr(value)
    end)

    self:assertEquals({[2] = '200', [4] = '400'}, array)
end

function _M:testWhereKey()

    local array = {[10] = 1, foo = 3, [20] = 2}
    array = tb.where(array, function(value, key)
        
        return lf.isNum(key)
    end)
    self:assertEquals({[10] = 1, [20] = 2}, array)
end

function _M:testForget()

    local array = {products = {desk = {price = 100}}}
    tb.forget(array, nil)
    self:assertEquals({products = {desk = {price = 100}}}, array)
    array = {products = {desk = {price = 100}}}
    tb.forget(array, {})
    self:assertEquals({products = {desk = {price = 100}}}, array)
    array = {products = {desk = {price = 100}}}
    tb.forget(array, 'products.desk')
    self:assertEquals({products = {}}, array)
    array = {products = {desk = {price = 100}}}
    tb.forget(array, 'products.desk.price')
    self:assertEquals({products = {desk = {}}}, array)
    array = {products = {desk = {price = 100}}}
    tb.forget(array, 'products.final.price')
    self:assertEquals({products = {desk = {price = 100}}}, array)
    array = {shop = {cart = {[150] = 0}}}
    tb.forget(array, 'shop.final.cart')
    self:assertEquals({shop = {cart = {[150] = 0}}}, array)
    array = {products = {desk = {price = {original = 50, taxes = 60}}}}
    tb.forget(array, 'products.desk.price.taxes')
    self:assertEquals({products = {desk = {price = {original = 50}}}}, array)
    array = {products = {desk = {price = {original = 50, taxes = 60}}}}
    tb.forget(array, 'products.desk.final.taxes')
    self:assertEquals({products = {desk = {price = {original = 50, taxes = 60}}}}, array)
    array = {products = {desk = {price = 50}}}
    tb.forget(array, {'products.amount.all', 'products.desk.price'})
    self:assertEquals({products = {desk = {}}}, array)
    -- Only works on first level keys
    array = {['joe@example.com'] = 'Joe', ['jane@example.com'] = 'Jane'}
    tb.forget(array, 'joe@example.com')
    self:assertEquals({['jane@example.com'] = 'Jane'}, array)
    -- Does not work for nested keys
    array = {emails = {['joe@example.com'] = {name = 'Joe'}, ['jane@localhost'] = {name = 'Jane'}}}
    tb.forget(array, {'emails.joe@example.com', 'emails.jane@localhost'})
    self:assertEquals({emails = {['joe@example.com'] = {name = 'Joe'}}}, array)
end

return _M

