
local lx, _M, mt = oo{
    _cls_       = ''
}

local app, lf, tb, str, new = lx.kit()
local fs = lx.fs

function _M:new()

    local this = {

    }

    return oo(this, mt)
end

function _M:run()

end

function _M:doRun(suite)

    local result = self:createTestResult()
    self:loadConf(result)

    local timing = app:get('app.timing')
    timing:start()

    local cmd = app:get('app.command')
    local printer = new('unit.resultPrinter', cmd)
    
    result:addListener(printer)
    suite:run(result)

    printer:printResult(result)

    return result
end

function _M:loadConf(result)

    local conf = app:conf('test')
    if conf.stopOnError then
        result:stopOnError(true)
    end

    if conf.stopOnError then
        result:stopOnError(true)
    end

    if conf.stopOnFailure then
        result:stopOnFailure(true)
    end

    if conf.stopOnWarning then
        result:stopOnWarning(true)
    end

    if conf.stopOnIncomplete then
        result:stopOnIncomplete(true)
    end

    if conf.stopOnRisky then
        result:stopOnRisky(true)
    end

    if conf.stopOnSkipped then
        result:stopOnSkipped(true)
    end

end

function _M:getTest()

    local files = self:getTestFiles()

    local suite = new('unit.testSuite')
    suite:addTestFiles(files)

    return suite
end

function _M:createTestResult()

    return new('unit.testResult')
end

function _M:getTestFiles()

    local conf = app:conf('test')
    local filter = conf.filter or ''
    local suffix = conf.suffix or 'Test'

    local files = fs.files(self:getTestPath(filter), 'f', function(file)

        local name, ext = file:sub(1, -5), file:sub(-3)

        if ext == 'lua' then
            if str.endsWith(name, suffix) then

                return self:getTestName(name)
            end
        end
    end)

    return files
end

function _M:getTestPath(filter)

    filter = filter or ''
    return lx.dir('test') .. filter
end

function _M:getTestName(name)

    local root = lx.dir('test')
    name = str.gsub(name, root, '')
    name = str.gsub(name, '/', '.')
    name = '.test.' .. name
    name = str.gsub(name, '%.%.', '.')
      
    return name
end

return _M

