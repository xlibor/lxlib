
local __ = {
    _cls_ = ''
}

-- System is unusable.
-- @param string message
-- @param table  context
-- @return void

function __:emergency(message, context) end

-- Action must be taken immediately.
-- Example: Entire website down, database unavailable, etc. This should
-- trigger the SMS alerts and wake you up.
-- @param string message
-- @param table  context
-- @return void

function __:alert(message, context) end

-- Critical conditions.
-- Example: Application component unavailable, unexpected exception.
-- @param string message
-- @param table  context
-- @return void

function __:critical(message, context) end

-- Runtime errors that do not require immediate action but should typically
-- be logged and monitored.
-- @param string message
-- @param table  context
-- @return void

function __:error(message, context) end

-- Exceptional occurrences that are not errors.
-- Example: Use of deprecated APIs, poor use of an API, undesirable things
-- that are not necessarily wrong.
-- @param string message
-- @param table  context
-- @return void

function __:warning(message, context) end

-- Normal but significant events.
-- @param string message
-- @param table  context
-- @return void

function __:notice(message, context) end

-- Interesting events.
-- Example: User logs in, SQL logs.
-- @param string message
-- @param table  context
-- @return void

function __:info(message, context) end

-- Detailed debug information.
-- @param string message
-- @param table  context
-- @return void

function __:debug(message, context) end

-- Logs with an arbitrary level.
-- @param mixed  level
-- @param string message
-- @param table  context
-- @return void

function __:log(level, message, context) end

return __

