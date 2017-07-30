
local _M = {
    _cls_ = '@sqlSelectTableJoinConditions'
}
local mt = { __index = _M }

local lx = require('lxlib')
local dbInit = lx.db

function _M:new()

    local this = {
        items = {},
        parent = {},
        logicalOperators = {}
    }

    setmetatable(this, mt)

    return this
end
 
function _M:add(leftTableField, compareOperator, rightTableField)

    if #self.logicalOperators < #self.items then
        self:addLogicalOperator('and')
    end
    local jcdt = dbInit.sqlSelectTableJoinCondition(leftTableField, compareOperator, rightTableField)
    tapd(self.items, jcdt)
    jcdt.parent = self

    return jcdt
end

function _M:addLogicalOperator(logicalOperator)

    if not logicalOperator then
        logicalOperator = 'and'
    end
    if #self.logicalOperators + 1 > #self.items then
        error('first call the add function - this function has been called without a prior call to add')
    end
    tapd(self.logicalOperators, logicalOperator)
end

function _M:sql(dbType)

    local sql = {}
    local count = #self.items
    local t

    for i,v in ipairs(self.items) do
        if i > 1 then
            tapd(sql, ' '..self.logicalOperators[i-1]..' ')
        end
        t = v:sql(dbType); tapd(sql, t) 
    end
    local strSql = table.concat(sql)
 
    return strSql
end

return _M

