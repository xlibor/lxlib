
local lx, _Ms = oos{}

local app, lf, tb, str = lx.kit()

local use, new

local _M = _Ms{
    _cls_ = 'main',
    _ext_ = 'unit.testCase'
}

function _M:ctor()

    if not use then
        use, new = lx.ns(self)
    end
end

function _M:testStringCanBeLimitedByWords()

    self:assertEquals('Taylor...', str.words('Taylor Otwell', 1))
    self:assertEquals('Taylor___', str.words('Taylor Otwell', 1, '___'))
    self:assertEquals('Taylor Otwell', str.words('Taylor Otwell', 3))
end

function _M:testStringTrimmedOnlyWhereNecessary()

    self:assertEquals(' Taylor Otwell ', str.words(' Taylor Otwell ', 3))
    self:assertEquals(' Taylor...', str.words(' Taylor Otwell ', 1))
end

function _M:testStringTitle()

    self:assertEquals('Jefferson Costella', str.title('jefferson costella'))
    self:assertEquals('Jefferson Costella', str.title('jefFErson coSTella'))
end

function _M:testStringWithoutWordsDoesntProduceError()

    local nbsp = str.char(0xc2) .. str.char(0xa0)
    self:assertEquals(' ', str.words(' '))
    self:assertEquals(nbsp, str.words(nbsp))
end

function _M:testStartsWith()

    self:assertTrue(str.startsWith('jason', 'jas'))
    self:assertTrue(str.startsWith('jason', 'jason'))
    self:assertTrue(str.startsWith('jason', {'jas'}))
    self:assertTrue(str.startsWith('jason', {'day', 'jas'}))
    self:assertFalse(str.startsWith('jason', 'day'))
    self:assertFalse(str.startsWith('jason', {'day'}))
    self:assertFalse(str.startsWith('jason', ''))
    self:assertFalse(str.startsWith('7', ' 7'))
    self:assertTrue(str.startsWith('7a', '7'))
    self:assertTrue(str.startsWith('7a', 7))
    self:assertTrue(str.startsWith('7.12a', 7.12))
    self:assertFalse(str.startsWith('7.12a', 7.13))
    self:assertTrue(str.startsWith(7.123, '7'))
    self:assertTrue(str.startsWith(7.123, '7.12'))
    self:assertFalse(str.startsWith(7.123, '7.13'))
end

function _M:testEndsWith()

    self:assertTrue(str.endsWith('jason', 'on'))
    self:assertTrue(str.endsWith('jason', 'jason'))
    self:assertTrue(str.endsWith('jason', {'on'}))
    self:assertTrue(str.endsWith('jason', {'no', 'on'}))
    self:assertFalse(str.endsWith('jason', 'no'))
    self:assertFalse(str.endsWith('jason', {'no'}))
    self:assertFalse(str.endsWith('jason', ''))
    self:assertFalse(str.endsWith('7', ' 7'))
    self:assertTrue(str.endsWith('a7', '7'))
    self:assertTrue(str.endsWith('a7', 7))
    self:assertTrue(str.endsWith('a7.12', 7.12))
    self:assertFalse(str.endsWith('a7.12', 7.13))
    self:assertTrue(str.endsWith(0.27, '7'))
    self:assertTrue(str.endsWith(0.27, '0.27'))
    self:assertFalse(str.endsWith(0.27, '8'))
end

function _M:testStrContains()

    self:assertTrue(str.contains('taylor', 'ylo'))
    self:assertTrue(str.contains('taylor', 'taylor'))
    self:assertTrue(str.contains('taylor', {'ylo'}))
    self:assertTrue(str.contains('taylor', {'xxx', 'ylo'}))
    self:assertFalse(str.contains('taylor', 'xxx'))
    self:assertFalse(str.contains('taylor', {'xxx'}))
    self:assertFalse(str.contains('taylor', ''))
end

function _M:testParseCallback()

    self:assertEquals({'Class', 'method'}, {str.parseCallback('Class@method', 'foo')})
    self:assertEquals({'Class', 'foo'}, {str.parseCallback('Class', 'foo')})
end

function _M:testSlug()

    self:assertEquals('hello-world', str.slug('hello world'))
    self:assertEquals('hello-world', str.slug('hello-world'))
    self:assertEquals('hello-world', str.slug('hello_world'))
    self:assertEquals('hello_world', str.slug('hello_world', '_'))
end

function _M:testFinish()

    self:assertEquals('abbc', str.finish('ab', 'bc'))
    self:assertEquals('abbc', str.finish('abbcbc', 'bc'))
    self:assertEquals('abcbbc', str.finish('abcbbcbc', 'bc'))
end

function _M:testIs()

    self:assertTrue(str.is('/', '/'))
    self:assertFalse(str.is(' /', '/'))
    self:assertFalse(str.is('/a', '/'))
    self:assertTrue(str.is('foo/bar/baz', 'foo/*'))
    self:assertTrue(str.is('blah/baz/foo', '*/foo'))
end

function _M:testKebab()

    self:assertEquals('laravel-php-framework', str.kebab('LaravelPhpFramework'))
end

function _M:testLower()

    self:assertEquals('foo bar baz', str.lower('FOO BAR BAZ'))
    self:assertEquals('foo bar baz', str.lower('fOo Bar bAz'))
end

function _M:testUpper()

    self:assertEquals('FOO BAR BAZ', str.upper('foo bar baz'))
    self:assertEquals('FOO BAR BAZ', str.upper('foO bAr BaZ'))
end

function _M:testLimit()

    self:assertEquals('Laravel is...', str.limit('Laravel is a free, open source PHP web application framework.', 10))
end

function _M:testLength()

    self:assertEquals(11, str.len('foo bar baz'))
end

function _M:testRandom()

    self:assertEquals(16, str.len(str.random()))
    local randomInteger = lf.rnd(1, 100)
    self:assertEquals(randomInteger, str.len(str.random(randomInteger)))
    self:assertInternalType('string', str.random())
end

function _M:testReplaceArray()

    self:assertEquals('foo/bar/baz', str.replaceArray('?/?/?', '?', {'foo', 'bar', 'baz'}))
    self:assertEquals('foo/bar/baz/?', str.replaceArray('?/?/?/?', '?', {'foo', 'bar', 'baz'}))
    self:assertEquals('foo/bar', str.replaceArray('?/?', '?', {'foo', 'bar', 'baz'}))
    self:assertEquals('?/?/?', str.replaceArray('?/?/?', 'x', {'foo', 'bar', 'baz'}))
end

function _M:testReplaceFirst()

    self:assertEquals('fooqux foobar', str.replaceFirst('foobar foobar', 'bar', 'qux'))
    self:assertEquals('foo/qux? foo/bar?', str.replaceFirst('foo/bar? foo/bar?', 'bar?', 'qux?'))
    self:assertEquals('foo foobar', str.replaceFirst('foobar foobar', 'bar', ''))
    self:assertEquals('foobar foobar', str.replaceFirst('foobar foobar', 'xxx', 'yyy'))
end

function _M:testReplaceLast()

    self:assertEquals('foobar fooqux', str.replaceLast('foobar foobar', 'bar', 'qux'))
    self:assertEquals('foo/bar? foo/qux?', str.replaceLast('foo/bar? foo/bar?', 'bar?', 'qux?'))
    self:assertEquals('foobar foo', str.replaceLast('foobar foobar', 'bar', ''))
    self:assertEquals('foobar foobar', str.replaceLast('foobar foobar', 'xxx', 'yyy'))
end

function _M:testSnake()

    self:assertEquals('laravel_p_h_p_framework', str.snake('LaravelPHPFramework'))
    self:assertEquals('laravel_php_framework', str.snake('LaravelPhpFramework'))
    self:assertEquals('laravel php framework', str.snake('LaravelPhpFramework', ' '))
    self:assertEquals('laravel_php_framework', str.snake('Laravel Php Framework'))
    self:assertEquals('laravel_php_framework', str.snake('Laravel    Php      Framework   '))
    -- ensure cache keys don't overlap
    self:assertEquals('laravel__php__framework', str.snake('LaravelPhpFramework', '__'))
    self:assertEquals('laravel_php_framework_', str.snake('LaravelPhpFramework_', '_'))
end

function _M:testStudly()

    self:assertEquals('LaravelPHPFramework', str.studly('laravel_p_h_p_framework'))
    self:assertEquals('LaravelPhpFramework', str.studly('laravel_php_framework'))
    self:assertEquals('LaravelPhPFramework', str.studly('laravel-phP-framework'))
    self:assertEquals('LaravelPhpFramework', str.studly('laravel  -_-  php   -_-   framework   '))
end

function _M:testCamel()

    self:assertEquals('laravelPHPFramework', str.camel('Laravel_p_h_p_framework'))
    self:assertEquals('laravelPhpFramework', str.camel('Laravel_php_framework'))
    self:assertEquals('laravelPhPFramework', str.camel('Laravel-phP-framework'))
    self:assertEquals('laravelPhpFramework', str.camel('Laravel  -_-  php   -_-   framework   '))
end

function _M:testSubstr()
    self:assertEquals('g', str.substr('abcdefg', -1))
    self:assertEquals('fg', str.substr('abcdefg', -2))
    self:assertEquals('e', str.substr('abcdefg', -3, 1))
    self:assertEquals('bcdef', str.substr('abcdefg', 2, -1))
    self:assertEmpty(str.substr('abcdefg', 4, -4))
    self:assertEquals('ef', str.substr('abcdefg', -3, -1))
    self:assertEquals('bcdefg', str.substr('abcdefg', 2))
    self:assertEquals('abc', str.substr('abcdefg', 1, 3))
    self:assertEquals('abcd', str.substr('abcdefg', 1, 4))
    self:assertEquals('g', str.substr('abcdefg', -1, 1))
    self:assertEmpty(str.substr('a', 2))
end

function _M:testUcfirst()

    self:assertEquals('Laravel', str.ucfirst('laravel'))
    self:assertEquals('Laravel framework', str.ucfirst('laravel framework'))

end

return _Ms

