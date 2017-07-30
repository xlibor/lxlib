
local _M = {
    _cls_ = '@sqlUpdate'
}
local mt = { __index = _M }

local pub = require('lxlib.db.pub')

function _M:new(tableName)

    local this = {
        fields = nil,
        conditions = nil,
        style = 0 ,
        tableName = tableName or ''
    }
    
    setmetatable(this, mt)

    return this
end

function _M:sql(dbType)

    local sql = {}
    local fields = self.fields.items
    local cdts = self.conditions
    local strFields, strValues
    local t
    if self.tableName == nil then
        error('tableName property has not been set.')
    end
     
    if next(fields) == 0 then
        error('field values have not been set.')
    end
 
    dbType = dbType or 'mysql'
 
    local tblFields = {}
    for i,v in pairs(fields) do
        t = pub.sqlWrapName(v.name,dbType)
        t = t..' = '..pub.sqlConvertValue(v.value,dbType)
        tapd(tblFields, t)
    end
    strFields = table.concat(tblFields,',')
 
    tapd(sql,'update ')
    local strTableName = pub.sqlWrapName(self.tableName,dbType)
    tapd(sql, strTableName..' set ')
    tapd(sql, strFields..' ')
    
    if cdts then
        if #cdts.conditions>0 then
            local strWhere = cdts:sql(dbType)
            if #strWhere then 
                tapd(sql, 'where '..strWhere)
            end
        end
    end
    --need todo update copyfield
    
    local strSql = table.concat(sql)
 
    return strSql
end
 
return _M

