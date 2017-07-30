
local _M = {
    _cls_ = '@sqlDelete'
}
local mt = { __index = _M }


local pub = require('lxlib.db.pub')

function _M:new(tableName)

    local this = {
        conditions = nil,
        style = 0,
        tableName = tableName or ''
    }
    
    setmetatable(this, mt)

    return this
end

function _M:sql(dbType)

    local sql = {}
    local cdts = self.conditions
    local t
    if not self.tableName then
        error('tableName has not been set.')
    end
 
    tapd(sql,'delete from ')
    local strTableName = pub.sqlWrapName(self.tableName,dbType)
    tapd(sql, strTableName..' ')

    if cdts then
        if #cdts.conditions>0 then
            local strWhere = cdts:sql(dbType)
            if #strWhere then 
                tapd(sql, 'where '..strWhere)
            end
        end
    end

    local strSql = table.concat(sql)
 
    return strSql
end
 
return _M

