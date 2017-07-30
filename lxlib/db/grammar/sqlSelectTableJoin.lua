
local _M = {
    _cls_ = '@sqlSelectTableJoin'
}
local mt = { __index = _M }

local lx = require('lxlib')
local dbInit = lx.db

function _M:new(leftTable, joinType, rightTable)

    local this = {
        leftTable = leftTable ,
        rightTable = rightTable ,
        conditions = {},
        parent = {},
        joinType = joinType or 'left join'
    }
    
    local conditions = dbInit.sqlSelectTableJoinConditions()
    conditions.parent = this
    this.conditions = conditions

    setmetatable(this, mt)

    return this
end
    
function _M:sql(dbType)
    
    local sql = {}
    local leftTable = self.leftTable
    local rightTable = self.rightTable
    local cdts = self.conditions

    if not rightTable then
        error('rightTable is nothing')
    end

    tapd(sql, ' '..self.joinType..' '..rightTable:sql(dbType))
    if cdts then
        local strCdts = cdts:sql(dbType)
        if strCdts then
            tapd(sql, ' on '..strCdts)        
        end
    end

    local strSql = table.concat(sql)
 
    return strSql
end
 
return _M

