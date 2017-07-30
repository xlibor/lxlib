
local lx, _M, mt = oo{
    _cls_       = '',
    _bond_      = 'iteratable'
}

local app, lf, tb, str, new = lx.kit()
local each = lf.each

function _M:new()

    local this = {
        tests               = {},
        numTests            = -1,
    }

    return oo(this, mt)
end

function _M:run(result)

    local hookMethods = {}

    self:setUp()

    for name, test in each(self) do
        if result:shouldStop() then
            break
        end

        test:run(result)
    end

    self:tearDown()

    result:endTestSuite(self)

    return result
end

function _M:setUp()

end

function _M:tearDown()

end

function _M:addTestFiles(files)

    for _, filename in ipairs(files) do
        self:addTestFile(filename)
    end
end

function _M:addTestFile(filename)

    local class
    local bag = lf.import(filename)
    if bag._clses_ then
        local subBag
        local classes = {}
        for k, v in pairs(bag) do
            if not str.startsWith(k, '_') then
                subBag = filename .. '@' .. k
                app:bind(k, subBag)
                classes[k] = subBag
            end
        end

        for k, v in pairs(classes) do
            class = new('class', k)
            if class:is('unit.testCase') then
                app:bind(v)
                self:addTest(v)
            end
        end
    else
        class = filename
        app:bind(filename)
        self:addTest(filename)
    end
end

function _M:addTest(test)

    tapd(self.tests, test)
end

function _M:getIterator()

    return new('unit.filter.testIterator', self)
end

function _M:toEach()

    return lf.toEach(self)
end

return _M

