
local __ = {
    _cls_ = ''
}

-- Checks whether the given record will be handled by this handler.
-- This is mostly done for performance reasons, to avoid calling processors for nothing.
-- Handlers should still check the record levels within handle(), returning false in isHandling()
-- is no guarantee that handle() will not be called, and isHandling() might not be called
-- for a given record.

-- @param table record Partial log record containing only a level key
-- @return boolean
function __:isHandling(record) end

-- Handles a record.
-- All records may be passed to this method, and the handler should discard
-- those that it does not want to handle.
-- The return value of this function controls the bubbling process of the handler stack.
-- Unless the bubbling is interrupted (by returning true), the Logger class will keep on
-- calling further handlers in the stack with a given log record.

-- @param  table   record The record to handle
-- @return boolean true means that this handler handled the record, and that bubbling is not permitted.
--                 false means the record was either not processed or that this handler allows bubbling.
function __:handle(record) end

-- Handles a set of records at once.
-- @param table records The records to handle (an table of record tables)
function __:handleBatch(records) end

-- Adds a processor in the stack.
-- @param function callback
-- @return self
function __:pushProcessor(callback) end

-- Removes the processor on top of the stack and returns it.
-- @return function
function __:popProcessor() end

-- Sets the formatter.
-- @param  formatterBond formatter
-- @return self
function __:setFormatter(formatter) end

-- Gets the formatter.
-- @return formatterBond
function __:getFormatter() end

return __

