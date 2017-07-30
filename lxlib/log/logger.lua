
local lx, _M, mt = oo{
    _cls_       = '',
    _bond_      = 'loggerBond',
    _static_    = {
        timezone = false,
        levels = {
            ['100'] = 'DEBUG',
            ['200'] = 'INFO',
            ['250'] = 'NOTICE',
            ['300'] = 'WARNING',
            ['400'] = 'ERROR',
            ['500'] = 'CRITICAL',
            ['550'] = 'ALERT',
            ['600'] = 'EMERGENCY'
        },
        debug       = 100,
        info        = 200,
        notice      = 250,
        warning     = 300,
        error       = 400,
        critical    = 500,
        alert       = 550,
        emergency   = 600,
    }
}

local app, lf, tb, str, new = lx.kit()
local static

function _M._init_(this)

    static = this.static
end

function _M:new()

    local this = {
    }
    
    return oo(this, mt)
end

-- @item string             name
-- @item table|null         handlers
-- @item table|null         processors

function _M:ctor(name, handlers, processors)

    processors = processors or {}
    handlers = handlers or {}
    self.name = name
    self.handlers = handlers
    self.processors = processors
end

-- @return string

function _M:getName()

    return self.name
end

-- Return a new cloned instance with the name changed
-- @return self

function _M:withName(name)

    local new = self:__clone()
    new.name = name
    
    return new
end

-- Pushes a handler on to the stack.
-- @param  logHandlerBond handler
-- @return self

function _M:pushHandler(handler)

    tb.unshift(self.handlers, handler)
    
    return self
end

-- Pops a handler from the stack
-- @return logHandlerBond

function _M:popHandler()

    if not self.handlers then
        lx.throw('logicException', 'You tried to pop from an empty handler stack.')
    end
    
    return tb.shift(self.handlers)
end

-- Set handlers, replacing all existing ones.
-- If a map is passed, keys will be ignored.
-- @param  logHandlerBond[] handlers
-- @return self

function _M:setHandlers(handlers)

    self.handlers = {}
    for _, handler in ipairs(tb.reverse(handlers)) do
        self:pushHandler(handler)
    end
    
    return self
end

-- @return logHandlerBond[]

function _M:getHandlers()

    return self.handlers
end

-- Adds a processor on to the stack.
-- @param func callback
-- @return self

function _M:pushProcessor(callback)

    if not lf.isFunc(callback) then
        lx.throw('invalidArgumentException', 'Processors must be valid funcs (callback or object with an __invoke method), ' .. var_export(callback, true) .. ' given')
    end
    tb.unshift(self.processors, callback)
    
    return self
end

-- Removes the processor on top of the stack and returns it.
-- @return func

function _M:popProcessor()

    if not self.processors then
        lx.throw('logicException', 'You tried to pop from an empty processor stack.')
    end
    
    return tb.shift(self.processors)
end

-- @return func[]

function _M:getProcessors()

    return self.processors
end

-- Adds a log record.
-- @param  int          level       The logging level
-- @param  mixed        message     The log message
-- @param  table|null   context     The log context
-- @return boolean                  Whether the record has been processed

function _M:addRecord(level, message, context)

    context = context or {}
    local handlers = self.handlers

    if not handlers then
        self:pushHandler(new('streamHandler', 'php://stderr', static.debug))
    end
    local levelName = static.getLevelName(level)

    -- check if any handler will handle this message so we can return early and save cycles
    
    local handlerIndex

    for i, handler in ipairs(handlers) do
        if handler:isHandling({level = level}) then
            handlerIndex = i
            break
        end
    end

    if not handlerIndex then
        
        return false
    end

    local ts = new('datetime')
    if static.timezone then
        ts:setTimezone(static.timezone)
    end

    local record = {
        message = tostring(message),
        context = context,
        level = level,
        level_name = levelName,
        channel = self.name,
        datetime = ts,
        extra = {}
    }
    for _, processor in ipairs(self.processors) do
        record = lf.call(processor, record)
    end

    local handler
    for i = handlerIndex, #handlers do
        handler = handlers[i]
        if handler:handle(record) then
            break
        end
    end

    return true
end

-- Gets all supported logging levels.
-- @return table Assoc table with human-readable level names => level codes.

function _M.s__.getLevels()

    return tb.flip(static.levels)
end

-- Gets the name of the logging level.
-- @param  int    level
-- @return string

function _M.s__.getLevelName(level)

    level = tostring(level)
    local name = static.levels[level]
    if not name then
        lx.throw('invalidArgumentException', 'Level "' .. level .. '" is not defined, use one of: ' .. str.join(tb.keys(static.levels), ', '))
    end
    
    return name
end

-- Checks whether the Logger has a handler that listens on the given level
-- @param   int     level
-- @return  boolean

function _M:isHandling(level)

    local record = {level = level}
    for _, handler in pairs(self.handlers) do
        if handler:isHandling(record) then
            
            return true
        end
    end
    
    return false
end

-- Adds a log record at an arbitrary level.
-- This method allows for compatibility with common interfaces.
-- @param  mixed        level   The log level
-- @param  mixed        message The log message
-- @param  table|null   context The log context
-- @return boolean Whether the record has been processed

function _M:log(level, message, context)

    return self:addRecord(level, message, context)
end

-- Adds a log record at the DEBUG level.
-- This method allows for compatibility with common interfaces.
-- @param  mixed        message The log message
-- @param  table|null   context The log context
-- @return boolean Whether the record has been processed

function _M:debug(message, context)

    context = context or {}
    
    return self:addRecord(static.debug, message, context)
end

_M.addDebug = _M.debug

-- Adds a log record at the INFO level.
-- This method allows for compatibility with common interfaces.
-- @param  mixed        message The log message
-- @param  table|null   context The log context
-- @return boolean Whether the record has been processed

function _M:info(message, context)

    context = context or {}
    
    return self:addRecord(static.info, message, context)
end

_M.addInfo = _M.info

-- Adds a log record at the NOTICE level.
-- This method allows for compatibility with common interfaces.
-- @param  mixed        message The log message
-- @param  table|null   context The log context
-- @return boolean Whether the record has been processed

function _M:notice(message, context)

    context = context or {}
    
    return self:addRecord(static.notice, message, context)
end

_M.addNotice = _M.notice

-- Adds a log record at the WARNING level.
-- This method allows for compatibility with common interfaces.
-- @param  mixed        message The log message
-- @param  table|null   context The log context
-- @return boolean Whether the record has been processed

function _M:warning(message, context)

    context = context or {}
    
    return self:addRecord(static.warning, message, context)
end

_M.warn = _M.warning
_M.addWarning = _M.warning

-- Adds a log record at the ERROR level.
-- This method allows for compatibility with common interfaces.
-- @param  mixed        message The log message
-- @param  table|null   context The log context
-- @return boolean Whether the record has been processed

function _M:error(message, context)

    context = context or {}
    
    return self:addRecord(static.error, message, context)
end

_M.err = _M.error
_M.addError = _M.error

-- Adds a log record at the CRITICAL level.
-- This method allows for compatibility with common interfaces.
-- @param  mixed        message The log message
-- @param  table|null   context The log context
-- @return boolean Whether the record has been processed

function _M:critical(message, context)

    context = context or {}
    
    return self:addRecord(static.critical, message, context)
end

_M.crit = _M.critical
_M.addCritical = _M.critical

-- Adds a log record at the ALERT level.
-- This method allows for compatibility with common interfaces.
-- @param  mixed        message The log message
-- @param  table|null   context The log context
-- @return boolean Whether the record has been processed

function _M:alert(message, context)

    context = context or {}
    
    return self:addRecord(static.alert, message, context)
end

_M.addAlert = _M.alert

-- Adds a log record at the EMERGENCY level.
-- This method allows for compatibility with common interfaces.
-- @param  mixed        message The log message
-- @param  table|null   context The log context
-- @return boolean Whether the record has been processed

function _M:emergency(message, context)

    context = context or {}
    
    return self:addRecord(static.emergency, message, context)
end

_M.emerg = _M.emergency
_M.addEmergency = _M.emergency

-- Set the timezone to be used for the timestamp of log records.
-- This is stored globally for all Logger instances
-- @param timezone tz Timezone object

function _M.s__.setTimezone(tz)

    static.timezone = tz
end

-- @param  int|str  level
-- @return int

function _M.s__.toLevel(level)

    if lf.isStr(level) then
        local t = static[level]
        if not t then
            error('invalid level:' .. level)
        end
        return t
    else
        return level
    end
end

function _M:useFiles(path, level)

    level = level or static.debug
    local handler = new('streamHandler', path, self:parseLevel(level))
    self:pushHandler(handler)
    handler:setFormatter(self:getDefaultFormatter())
end

function _M:useDailyFiles(path, days, level)

    level = level or static.debug
    days = days or 0
    local handler = new('dailyFileHandler', path, days, self:parseLevel(level))
    self:pushHandler(handler)
    handler:setFormatter(self:getDefaultFormatter())
end

function _M:useSyslog(name, level)

    level = level or static.debug
    name = name or 'lxlib'
    
    return self:pushHandler(new('syslogHandler', name, LOG_USER, level))
end

function _M:useErrorLog(level, messageType)

    messageType = messageType or 0
    level = level or 'debug'
    local handler = new('errorLogHandler', messageType, self:parseLevel(level))
    self:pushHandler(handler)
    handler:setFormatter(self:getDefaultFormatter())
end

function _M:listen(callback)

    if not self.dispatcher then
        lx.throw('runtimeException', 'Events dispatcher has not been set.')
    end
    self.dispatcher:listen('illuminate.log', callback)
end

function _M.__:fireLogEvent(level, message, context)

    context = context or {}
    
    if self.dispatcher then
        self.dispatcher:fire('illuminate.log', compact('level', 'message', 'context'))
    end
end

function _M.__:parseLevel(level)

    return static.toLevel(level)
end

return _M

