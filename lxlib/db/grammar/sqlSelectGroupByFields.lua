
local GroupByField = {
    _cls_ = '@sqlSelectGroupByField'
}
local mt = { __index = GroupByField }

local lx = require('lxlib')
local dbInit = lx.db
local pub = require('lxlib.db.pub')

function GroupByField:new(name, tbl)

    local this = {
        name = name,
        table = tbl or {}
    }
    
    setmetatable(this, mt)

    return this
end

function GroupByField:sql(dbType)

    local sql
    sql = pub.addTablePre(self.table, self.name, dbType)

    return sql
end

local GroupByFields = {
    _cls_ = '@sqlSelectGroupByFields'
}
local mt = { __index = GroupByFields }

function GroupByFields:new()

    local this = {
        items = {}
    }
    
    setmetatable(this, mt)

    return this
end
 
function GroupByFields:add(fieldName, tbl)
    
    local field = GroupByField:new(fieldName, tbl)
    tapd(self.items, field)

    return field
end

function GroupByFields:sql(dbType)

    local sql = ''
    local count = #self.items
    for i,v in ipairs(self.items) do
        sql = sql .. v:sql(dbType)
        if i < count then sql = sql .. ', ' end
    end

    return sql
end

return GroupByFields

