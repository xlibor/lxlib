
local _M = {
    _cls_ = '@sqlSelectFields'
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
 
function _M:add(fieldName, tbl, alias, aggregateFunc, otherFuncOrExp)

    local field = dbInit.sqlSelectField(fieldName, tbl, alias, aggregateFunc)
    if otherFuncOrExp then
        local i = string.find(otherFuncOrExp, '%(')
        if i then 
            field.otherFuncExp = otherFuncOrExp
        else
            field.otherFunc = otherFuncOrExp        
        end
    end
    tapd(self.items, field)

    return field
end
 
function _M:sql(dbType)

    local sql = {}
    local count = #self.items
    if count == 0 then
        tapd(sql, '*')
    else
        for i,v in ipairs(self.items) do
            tapd(sql, v:sql(dbType))
            if i < count then tapd(sql, ', ') end
        end
    end
    local strSql = table.concat(sql)
 
    return strSql
end

return _M

