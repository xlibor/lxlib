
local __ = {
    _cls_ = ''
}

-- Formats a log record.
-- @param  table record A record to format
-- @return mixed The formatted record

function __:format(record) end

-- Formats a set of log records.
-- @param  table records A set of records to format
-- @return mixed The formatted set of records

function __:formatBatch(records) end

return __

