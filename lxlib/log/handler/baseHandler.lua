
local lx, _M, mt = oo{
    _cls_ = '',
    _bond_ = 'logHandlerBond',
    a__ = {}
}

local app, lf, tb, str, new = lx.kit()
local Logger = lx.use('logger')

function _M:new()

    local this = {
        processors = {}
    }
    
    return oo(this, mt)
end

-- @param int     level  The minimum logging level at which this handler will be triggered
-- @param boolean bubble Whether the messages that are handled can bubble up the stack or not

function _M:ctor(level, bubble)

    bubble = bubble or true
    level = level or Logger.static.debug
    self:setLevel(level)
    self.bubble = bubble
end

-- {@inheritdoc}

function _M:handle(record)

    if not self:isHandling(record) then
        
        return false
    end
    record = self:processRecord(record)
    record.formatted = self:getFormatter():format(record)
    self:write(record)
    
    return not self.bubble
end

-- Writes the record down to the log of the implementing handler
-- @param  table record

function _M.a__:write(record) end

-- Processes a record.
-- @param  table record
-- @return table

function _M.__:processRecord(record)

    if self.processors then
        for _, processor in pairs(self.processors) do
            record = lf.call(processor, record)
        end
    end
    
    return record
end

-- {@inheritdoc}

function _M:isHandling(record)

    return record.level >= self.level
end

-- {@inheritdoc}

function _M:handleBatch(records)

    for _, record in ipairs(records) do
        self:handle(record)
    end
end

-- Closes the handler.
-- This will be called automatically when the object is destroyed

function _M:close()

end

-- {@inheritdoc}

function _M:pushProcessor(callback)

    if not lf.isCallable(callback) then
        lx.throw('invalidArgumentException', 'Processors must be valid callables (callback or object with an __call method)')
    end
    tb.unshift(self.processors, callback)
    
    return self
end

-- {@inheritdoc}

function _M:popProcessor()

    if not self.processors then
        lx.throw('logicException', 'You tried to pop from an empty processor stack.')
    end
    
    return tb.shift(self.processors)
end

-- {@inheritdoc}

function _M:setFormatter(formatter)

    self.formatter = formatter
    
    return self
end

-- {@inheritdoc}

function _M:getFormatter()

    if not self.formatter then
        self.formatter = self:getDefaultFormatter()
    end
    
    return self.formatter
end

-- Sets minimum logging level at which this handler will be triggered.
-- @param  int|string   level Level or level name
-- @return self

function _M:setLevel(level)

    self.level = Logger.toLevel(level)
    
    return self
end

-- Gets minimum logging level at which this handler will be triggered.
-- @return int

function _M:getLevel()

    return self.level
end

-- Sets the bubbling behavior.
-- @param  boolean bubble true means that this handler allows bubbling.
--                         false means that bubbling is not permitted.
-- @return self

function _M:setBubble(bubble)

    self.bubble = bubble
    
    return self
end

-- Gets the bubbling behavior.
-- @return boolean true means that this handler allows bubbling.
--                 false means that bubbling is not permitted.

function _M:getBubble()

    return self.bubble
end

-- Gets the default formatter.
-- @return logFormatterBond

function _M.__:getDefaultFormatter()

    return new('logLineFormatter', nil, nil, true, true)
end

return _M

