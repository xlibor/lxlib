
local _M = {
    _cls_ = '@sqlSelectTables'
}
local mt = { __index = _M }

local lx = require('lxlib')
local dbInit = lx.db

function _M:new()

    local this = {
        items = {}
        -- tableJoins = {}
    }
 
    setmetatable(this, mt)

    return this
end

function _M:add(name, alias)

    local field = dbInit.sqlSelectTable(name, alias)
    tapd(self.items, field)
    
    return field
end
 
function _M:count()

    return #self.items
end

function _M:sql(dbType)
    
    local sql = {}
    local count = #self.items
    local bAddTable = false
    local joins = self.tableJoins
    local t

    for i,v in ipairs(self.items) do
        if not joins then 
            bAddTable = true 
        elseif not joins:exists(v) then
            bAddTable = true 
        else
            bAddTable = false     
        end
        if bAddTable then
            t = v:sql(dbType); tapd(sql,t)
        end
    end

    local strSql = table.concat(sql, ', ')
 
    if joins then
        local strJoins = joins:sql(dbType)
        strSql = strSql .. '' .. strJoins
    end

    return strSql
end
 
return _M

