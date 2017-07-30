
local lx, _M = oo{ 
    _cls_ = '',
    _ext_ = 'manager'
}

local app, lf, tb, str, new = lx.kit()

function _M:ctor()

    self.logger = app('logger', 'local')
end

function _M:driver(driver)

    return self:resolve(driver)
end

function _M:createDailyFileDriver(config)

    local fileName = app:conf('log.fileName')
    local level, bubble, maxFiles = config.level, config.bubble, config.maxFiles
    level = self.logger:parseLevel(level)

    local dailyFileHandler = app:make('logDailyFileHandler',
        fileName, level, bubble, maxFiles)

    return self:pushToLogger(dailyFileHandler, config)
end

function _M:createFileDriver(config)

    local fileName = app:conf('log.fileName')
    local level, bubble = config.level, config.bubble
    level = self.logger:parseLevel(level)

    local fileHandler = app:make('logFileHandler',
        fileName, level, bubble)

    return self:pushToLogger(fileHandler, config)
end

function _M:createErrorLogDriver(config)

    local errorLogHandler = app:make('logErrorLogHandler', config)

    return errorLogHandler
end

function _M:pushToLogger(handler, config)

    local formatter = self:createFormatter(config)
    handler:setFormatter(formatter)

    self.logger:pushHandler(handler)
    
    return handler
end

function _M:createFormatter(config)

    local formatter = config.formatter
    local vt = type(formatter)
    if formatter then
        if vt == 'table' then
            formatter = formatter[1]
        end
    end

    formatter = self:getFormatter(formatter)
    if vt == 'table' then
        local args = tb.clone(config.formatter)
        tb.shift(args)
        formatter = new(formatter, unpack(args))
    else
        formatter = new(formatter)
    end

    return formatter
end

function _M.__:getConfig(name)

    return app:conf('log.handlers.' .. name)
end

function _M:getDefaultDriver()

    return app:conf('log.default')
end

function _M:getFormatter(formatter)

    if not formatter then
        formatter = app:conf('log.formatter')
    end

    formatter = 'log' .. str.ucfirst(formatter) .. 'Formatter'

    return formatter
end

function _M:getLogger()

    return self.logger
end

function _M:_run_(method)

    return 'getLogger'
end

return _M

