
local _M = {
    _cls_ = '@sqlSelectTableJoinCondition'
}
local mt = { __index = _M }

local pub = require('lxlib.db.pub')

function _M:new(leftTableField, compareOperator, rightTableField)
    local this = {
        leftTableField = leftTableField,
        rightTableField = rightTableField,
        co = compareOperator
        --parent = objSqlSelectTableJoinConditions
    }
    
    setmetatable(this, mt)

    return this
end

function _M:sql(dbType)
    local sql = {}
    local t
    if not self.leftTableField then 
        error('leftTableFieldName has not been specified.')
    end
    if not self.rightTableField then 
        error('rightTableField has not been specified.')
    end

    local leftTable = self.parent.parent.leftTable
    local rightTable = self.parent.parent.rightTable

    t = pub.addTablePre(leftTable, self.leftTableField, dbType)
    tapd(sql, t)
    tapd(sql, self.co)
    t = pub.addTablePre(rightTable, self.rightTableField, dbType)
    tapd(sql, t)

    local strSql = table.concat(sql, ' ')
 
    return strSql 
end

return _M

