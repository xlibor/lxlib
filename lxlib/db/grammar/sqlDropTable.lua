
local _M = {
    _cls_ = '@sqlDropTable'
}
local mt = { __index = _M }

local pub = require('lxlib.db.pub')

function _M:new(tableName, ifExists)

    local this = {
        tableName = tableName,
        ifExists = ifExists
    }
    
    setmetatable(this, mt)

    return this
end

function _M:sql(dbType)

    local tableName = self.tableName

    if not tableName then
        error('tableName has not been set.')
    end

    local strTableName = pub.sqlWrapName(tableName, dbType)
    local ifExists = self.ifExists and 'if exists ' or ''
    local strSql = 'drop table '..ifExists..strTableName
 
    return strSql
end
 
return _M

