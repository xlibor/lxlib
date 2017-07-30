
local _M = {
    _cls_ = '@sqlTableExists'
}
local mt = { __index = _M }

local pub = require('lxlib.db.pub')
local fmt = string.format

function _M:new(tableName, dbName)

    local this = {
        tableName = tableName,
        dbName = dbName
    }
    
    setmetatable(this, mt)

    return this
end

function _M:sql(dbType)

    local sql

    if dbType == 'mysql' then
        sql = "select * from information_schema.tables where table_schema = '%s' and table_name = '%s'"
        sql = fmt(sql, self.dbName, self.tableName)
    else

    end

    return sql
end
 
return _M

