
local __ = {
    _cls_ = ''
}

function __:exec(sql) end

function __:query(sql) end

function __:prepare(sql, options) end

function __:quote(str, style) end

function __:beginTransaction() end

function __:rollback() end

function __:commit() end

function __:inTransaction() end

function __:getAttribute() end

function __:setAttr() end

function __:lastInsertId() end

function __:errorInfo() end

function __:errorCode() end

function __:getAvailableDrivers() end

return __

