
local _M = {
    _cls_ = '@sqlCommonGrammar'
}
local mt = { __index = _M }

local pub = require('lxlib.db.pub')

local lx = require('lxlib')
local dbInit = lx.db

function _M:new(dbType)
    
    local this = {
        dbType = dbType
    }

    setmetatable(this, mt)

    return this
end

function _M:enableForeignKeyConstraints()

    local sql
    local dbType = self.dbType

    if dbType == 'mysql' then
        sql = 'SET FOREIGN_KEY_CHECKS=1;'
    elseif dbType == 'pgsql' then
        sql = 'SET CONSTRAINTS ALL IMMEDIATE;'
    elseif dbType == 'sqlite' then
        sql = 'PRAGMA foreign_keys = ON;'
    end

    return sql
end

function _M:disableForeignKeyConstraints()

    local sql
    local dbType = self.dbType

    if dbType == 'mysql' then
        sql = 'SET FOREIGN_KEY_CHECKS=0;'
    elseif dbType == 'pgsql' then
        sql = 'SET CONSTRAINTS ALL DEFERRED;'
    elseif dbType == 'sqlite' then
        sql = 'PRAGMA foreign_keys = OFF;'
    end

    return sql
end

function _M:truncate(table)

    local sql
    local dbType = self.dbType
    local table = self:wrap(table)

    if dbType == 'mysql' then
        sql = {'truncate ' .. table}
    elseif dbType == 'pgsql' then
        sql = {'truncate ' .. table .. ' restart identity'}
    elseif dbType == 'sqlite' then
        sql = {
            'delete from sqlite_sequence where name = ' .. table,
            'delete from ' .. table
        }
    end

    return sql
end

function _M:wrap(value)

    local dbType = self.dbType
    return pub.sqlWrapName(value, dbType)
end

return _M

