
local _M ={
    _cls_ = '@sqlInsert'
}
local mt = { __index = _M }

local pub = require('lxlib.db.pub')

function _M:new(tableName)

    local this = {
        dbType = 'mysql',
        fields = nil,
        style = 0 ,
        tableName = tableName or ''
    }
    
    setmetatable(this, mt)

    return this
end

function _M:sql(dbType)

    local sql = {}
    local fields = self.fields.items
    local strFields, strValues
    local t
    if self.tableName == nil then
        error('tableName property has not been set.')
    end
     
    if not next(fields) then
        error('field values have not been set.')
    end
    
    if not dbType then 
        dbType = self.dbType
    end
    
    local tblFields = {}
    for _,v in pairs(fields) do
        tapd(tblFields, pub.sqlWrapName(v.name, dbType))
    end

    strFields = table.concat(tblFields, ',')
 
    local tblValues = {}
    for _, v in pairs(fields) do
        tapd(tblValues, pub.sqlConvertValue(v.value, dbType))
    end

    strValues = table.concat(tblValues,',')
 
    local strStyle = (self.style == 0) and 'insert' or 'replace'
    tapd(sql, strStyle..' into ')
    local strTableName = pub.sqlWrapName(self.tableName, dbType)
    tapd(sql, strTableName..' ')
    tapd(sql, '('..strFields..') ')
    tapd(sql, 'values ('..strValues..')')
    
    -- TODO: ON DUPLICATE KEY UPDATE
    
    local strSql = table.concat(sql)
 
    return strSql
end
 
return _M

