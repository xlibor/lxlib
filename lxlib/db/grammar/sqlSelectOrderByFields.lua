
local OrderByField = {
    _cls_ = '@sqlSelectOrderByField'
}
local mt = { __index = OrderByField }

local lx = require('lxlib')
local dbInit = lx.db
local pub = require('lxlib.db.pub')

function OrderByField:new(field, tbl, order, aggregateFunc)
    
    local this = {
        field = field,
        table = tbl or {},
        order = order,
        aggregateFunc = aggregateFunc
    }
 
    setmetatable(this, mt)

    return this
end

function OrderByField:sql(dbType)

    local sql
    local field = self.field
    local fieldType = type(field)

    if fieldType == 'string' then
        sql = pub.addTablePre(self.table, field, dbType)
    elseif fieldType == 'table' then

        sql = pub.sqlConvertField(field)
    end

    if self.aggregateFunc then 
        sql = self.aggregateFunc .. '(' .. sql .. ')'
    end
    if self.order then 
        if self.order == 'desc' then 
            sql = sql .. ' desc'
        end
    end

    return sql
end

local OrderByFields = {
    _cls_ = '@sqlSelectOrderByFields'
}
local mt = { __index = OrderByFields }

function OrderByFields:new()

    local this = {
        items = {}
    }

    setmetatable(this, mt)

    return this
end

function OrderByFields:add(fieldName, tbl, order, aggregateFunc)

    local field = OrderByField:new(fieldName, tbl, order, aggregateFunc)
    tapd(self.items, field)
    return field
end

function OrderByFields:sql(dbType)

    local sql = ''
    local count = #self.items
    for i, v in ipairs(self.items) do
        sql = sql .. v:sql(dbType)
        if i < count then sql = sql .. ', ' end
    end

    return sql
end

return OrderByFields

