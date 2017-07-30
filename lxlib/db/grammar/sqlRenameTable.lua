
local _M = {
    _cls_ = '@sqlRenameTable'
}
local mt = { __index = _M }

local pub = require('lxlib.db.pub')

function _M:new(tableFrom, tableTo)

    local this = {
        tableFrom = tableFrom,
        tableTo = tableTo
    }
    
    setmetatable(this, mt)

    return this
end

function _M:sql(dbType)

    local tableFrom = self.tableFrom
    local tableTo = self.tableTo

    if not tableFrom then
        error('tableFrom has not been set.')
    end
    if not tableTo then
        error('tableTo has not been set.')
    end

    tableFrom = pub.sqlWrapName(tableFrom, dbType)
    tableTo = pub.sqlWrapName(tableTo, dbType)

    local strSql = fmt('rename table %s to %s', tableFrom, tableTo)
 
    return strSql
end
 
return _M

