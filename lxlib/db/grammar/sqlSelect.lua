
local _M = {
    _cls_ = '@sqlSelect'
}
local mt = { __index = _M }

function _M:new()

    local this = {
        dbType = 'mysql',
        fields = nil,
        tables = nil,
        conditions = nil,
        orderByFields = nil,
        groupByFields = nil,
        havings = nil,
        distinct = false,
        top = 0
    }
    
    setmetatable(this, mt)

    return this
end

function _M:sql(dbType)

    local sql = {}
    local fields = self.fields
    local tables = self.tables
    local cdts = self.conditions
    local groupBy = self.groupByFields
    local orderBy = self.orderByFields
    local limit = self.limitField
    local havings = self.havings

    if not dbType then 
        dbType = self.dbType
    end
    
    if #self.tables == 0 then 
         -- error('The table has not been set.')
    end
    tapd(sql, 'select ')
    if self.distinct then 
        tapd(sql, 'distinct ')
    end
    if self.top > 0 then
        tapd(sql, ' TOP '..self.top)
    end

    if fields then 
        tapd(sql, fields:sql(dbType))
    end

    tapd(sql, ' from ')

    local fromRaw = self.fromRaw
    if fromRaw then
        tapd(sql, fromRaw:sql(dbType))
    else
        if tables then
            tapd(sql, tables:sql(dbType))
        end
    end

    if cdts then
        local strCdts = cdts:sql(dbType) or '()'
        if strCdts ~='()' then
            tapd(sql, ' where ' .. strCdts)        
        end
    end

    if groupBy then
        local strGroupBy = groupBy:sql(dbType)
        if strGroupBy then
            tapd(sql, ' group by ' .. strGroupBy)
        end
    end

    if havings then
        local strHaving = havings:sql(dbType)
        if strHaving then
            tapd(sql, ' having ' .. strHaving)
        end
    end

    if orderBy then
        local strOrderBy = orderBy:sql(dbType)
        if strOrderBy then
            tapd(sql, ' order by '..strOrderBy)
        end
    end

    if limit then
        local strLimit = limit:sql(dbType)
        if strLimit then
            tapd(sql, strLimit)
        end
    end

    local strSql = table.concat(sql)
 
    return strSql
end

return _M

