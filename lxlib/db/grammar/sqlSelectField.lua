
local _M = {
    _cls_ = '@sqlSelectField'
}
local mt = { __index = _M }

local pub = require('lxlib.db.pub')

function _M:new(name, tbl, alias, aggregateFunc)

    local this = {
        name = name,
        table = tbl or {},
        alias = alias,
        aggregateFunc = aggregateFunc
        -- otherFuncExp,otherFunc
    }
    if aggregateFunc == 'distinct' then
        this.distinct = true
    end
    
    setmetatable(this, mt)

    return this
end

function _M:sql(dbType)

    local sql = {}
    if self.distinct then
        tapd(sql, 'DISTINCT ')
    end

    if self.aggregateFunc and not self.distinct then
        tapd(sql, self.aggregateFunc .. '(')
    end

    if self.otherFunc then
        tapd(sql, self.otherFunc .. '(')
    end

    if self.aggregateFunc then
        if not self.name and self.aggregateFunc == 'count' then
            tapd(sql, '*')
        elseif self.name then
            tapd(sql, pub.addTablePre(self.table, self.name, dbType))
        end
    else
        if self.name then
            tapd(sql, pub.addTablePre(self.table, self.name, dbType))
        end
    end

    if self.aggregateFunc and not self.distinct then
        tapd(sql, ')')
    end

    if self.otherFunc then
        tapd(sql, ')')
    end

    local strSql = table.concat(sql)
 
    local i = string.find(strSql,'%(')
    if self.otherFuncExp and not i then
        strSql = self.otherFuncExp
    end

    if self.alias then
        strSql = strSql .. ' as ' .. pub.addTablePre(self.table, self.alias, dbType)
    end
 
    return strSql
end
 
return _M