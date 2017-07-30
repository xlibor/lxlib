
local lx, _M, mt = oo{
    _cls_       = '',
    _bond_      = 'iterator'
}

local app, lf, tb, str, new = lx.kit()
local fs = lx.fs
local methodPrefix = 'test'

function _M._init_()
    local conf = app:conf('test')
    local t = conf.methodPrefix
    if t then
        methodPrefix = t
    end
end

function _M:new()

    local this = {
    }

    return oo(this, mt)
end

function _M:ctor(suite)

    self.testClasses = suite.tests
    self.tests = {}
end

function _M:toEach()
    
    return lf.toEach(self)
end

function _M:rewind()

    self.classIndex = 1

    self:findTests()
end

function _M:findTests()

    self.tests = {}
    self.methodIndex = 1

    local class, methods
    for i = self.classIndex, #self.testClasses do
        class = self.testClasses[i]
        methods = self:getTestMethods(class)
        if #methods > 0 then
            self.tests = methods
            break
        end
    end
end

function _M:valid()

    if #self.tests == 0 then
        return false
    end

    if self.methodIndex > #self.tests then
        return false
    end

    return true
end

function _M:key()

    return self:getCurrentClass()
end

function _M:getCurrentClass()

    return self.testClasses[self.classIndex]
end

function _M:getCurrentMethod()

    return self.tests[self.methodIndex]
end

function _M:current()

    local class = self:getCurrentClass()
    local method = self:getCurrentMethod()
    local test = new(class, method)

    return test
end

function _M:next()

    self.methodIndex = self.methodIndex + 1
    if self.methodIndex > #self.tests then
        self.classIndex = self.classIndex + 1
        self:findTests()
    end
end

function _M:getTestMethods(class)

    local methods = {}
    local bag

    bag = app:getClsBaseInfo(class).bag
    for k, v in pairs(bag) do
        if type(v) == 'function' and
            str.startsWith(k, methodPrefix) then
            tapd(methods, k)
        end
    end

    return methods
end

return _M

