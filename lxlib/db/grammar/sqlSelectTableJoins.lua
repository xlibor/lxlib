
local _M = {
    _cls_ = '@sqlSelectTableJoins'
}
local mt = { __index = _M }

local lx = require('lxlib')
local dbInit = lx.db

function _M:new()

    local this = {
        items = {}
    }
 
    setmetatable(this, mt)

    return this
end
 
function _M:add(leftTable, joinType, rightTable)

    local tableJoin = dbInit.sqlSelectTableJoin(leftTable, joinType, rightTable)
    
    tableJoin.parent = self
    tapd(self.items, tableJoin)

    return tableJoin
end

function _M:addJoin(tableJoin)
    
    tableJoin.parent = self
    tapd(self.items, tableJoin)
end

function _M:exists(selectTable)
    
    local exists = false
    local exit = false

    for _,v in pairs(self.items) do
        if not exit then
            if v.leftTable == selectTable or v.rightTable == selectTable then
                exists = true
                exit = true
            end
        end
    end

    return exists
end

function _M:sql(dbType)

    local sql = {}
    local t
    for _,v in pairs(self.items) do
        t = v:sql(dbType); tapd(sql,t)
    end

    local strSql = table.concat(sql)
 
    return strSql
end
 
return _M

