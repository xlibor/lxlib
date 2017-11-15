
local _M = {
    _cls_ = '',
    _ext_ = 'lxlib.db.ldo.ldo'
}

local mt = { __index = _M }

local sqlite = require('lxlib.db.ldo.driver.sqlite.base')
local error = error
local ipairs = ipairs
local pairs = pairs
local require = require
local tonumber = tonumber


local function connect(options)
    options = options or {}
    local dbPath = options.database
    local db, err = sqlite.DBConnection:open(dbPath)
    
    return db, err
end

function _M:trace()
    if ngx.ctx.lxormDebug then 
        ngx.say('sqliteSql:', self.sql, '=====')
    end
end

function _M:new(options)
    local this = {
        options = options, 
        _inTrans = false,
        sql = ''
    }
 
    local db = connect(options)
    if not db then
        error('open db failed')
    else
        this.db = db
    end

    setmetatable(this, mt)

    return this
end

function _M:createTable(...)
    local args = {...}
    local argsLen = #args
    local name, columns, key, rawSql

    if argsLen == 1 then
        rawSql = args[1]
    elseif argsLen > 1 then
        name, columns, key = args[1], args[2], args[3]
    end
 
    local db = self.db
    local params = { Name = name, Columns = columns, Key = key, Sql = rawSql }
    local tbl, rc, err = db:createTable(params)

    if tbl then 
        self.sql = rc
        self:trace()
        return tbl
    else 
        return nil, err
    end
end

function _M:dropTable(tblName)
    local db = self.db

    return db:dropTable(tblName)
end

function _M:lastInsertId()
    local db = self.db
    return db:getLastRowID()
end

function _M:insertTable(tblName, p1, p2)
    local values, columns
    if p1 and p2 then
        values, columns = p2, p1
    elseif p1 then
        values = p1
    end

    local strSql
    local strValues, strCols, vTbl, colTbl = '', '', {}, {}
    if not columns then
        local t1 = values[1]
        if t1 then
            for _, v in ipairs(values) do
                if type(v) == 'string' then v = "'" .. v .. "'" end
                tapd(vTbl, v)
            end
            strValues = table.concat(vTbl, ',')
            strSql = string.format("INSERT INTO %s VALUES (%s)", tblName, strValues)
        else
            for k, v in pairs(values) do
                if type(v) == 'string' then v = "'" .. v .. "'" end
                tapd(colTbl, k)
                tapd(vTbl, v)
            end
            strCols = table.concat(colTbl, ',')
            strValues = table.concat(vTbl, ',')
            strSql = string.format("INSERT INTO %s (%s) VALUES (%s)", tblName, strCols, strValues)
        end
    else 
        strCols = table.concat(columns, ',')
        for _, v in ipairs(values) do
            if type(v) == 'string' then v = "'" .. v .. "'" end
            tapd(vTbl, v)
        end
        strValues = table.concat(vTbl, ',')

        strSql = string.format("INSERT INTO %s (%s) VALUES (%s)", tblName, strCols, strValues)
    end
 
    return self:exec(strSql)
end

function _M:updateTable(tblName, values, clause)
    local sql = {}
    tapd(sql, 'update ' .. tblName .. ' set ')

    local typeValues = type(values)
    if typeValues == 'string' then
        tapd(sql, values)
    elseif typeValues == 'table' then
        local vTbl = {}
        for k,v in pairs(values) do
            if type(v) == 'string' then
                v = "'" .. v .. "'"
            end
            tapd(vTbl, k .. '=' .. v)
        end
        local strValues = table.concat(vTbl, ',')
        tapd(sql, strValues)
    end

    if clause then
        local typeClause = type(clause)
        if typeClause == 'string' then
            tapd(sql, ' where ' .. clause)
        elseif typeClause == 'table' then
            local clauseTbl = {}
            for k,v in pairs(clause) do
                if type(v) == 'string' then
                    v = "'" .. v .. "'"
                end
                tapd(clauseTbl, k .. '=' .. v)
            end
            local strClause = table.concat(clauseTbl, ' and ')
            tapd(sql, ' where ' .. strClause)
        end
    end

    local strSql = table.concat(sql)
 
    return self:exec(strSql)
end

function _M:getRs(sql, isNeedList)

    local rs = {}
    local db = self.db
    local stmt, rc = db:prepare(sql)

    if stmt then
        rs = stmt:rows(isNeedList)
    else
        error('sqlite error:' .. rc)
    end

    self.sql = sql
    self:trace()

    return rs
end

function _M:openRs(sql, isNeedList)
    local rs = {}
    local db = self.db
    local stmt, rc = db:prepare(sql)

    if stmt then
        rs = stmt:results(isNeedList)
    else
        error('sqlite error:' .. rc)
    end

    self.sql = sql
    self:trace()
    return rs
end

function _M:query(sql, isNeedList)

    return self:getRs(sql, isNeedList)
end

function _M:exec(sql)
 
    local db = self.db
    local rc, err = db:exec(sql)
     
    self.sql = sql
    self:trace()
     
    if rc ~= 0 then
        error(err)
        return nil, err
    else 
        return true
    end
end

function _M:initTableFrom(data, tblName)
    
    local columns = {}
    local firstRow = data[1]
    for k, _ in pairs(firstRow) do
        tapd(columns, k)
    end
    local columnsStr = table.concat(columns, ',')

    local db = self.db
    local tbl, err = self:createTable(tblName, columnsStr)
    if not tbl then 
        error(err)
    end
    
    local values, value, valuesStr
    local sql 
    for _, row in ipairs(data) do
        values = {}
        for _, value in pairs(row) do
            if type(value) == 'string' then
                value = "'" .. value .. "'"
            end
            tapd(values, value)
        end
        valuesStr = table.concat(values, ',')
        _, sql = tbl:insertValues( {Values = valuesStr} )
        self.sql = sql
        self:trace()
    end

end

function _M:beginTrans()
    if self._inTrans then
        error('already in trans')
    else
        self._inTrans = true
        local res = self:exec('BEGIN;')
        if res then 
            return true
        else
            self._inTrans = false
            return false
        end
    end
end

function _M:commitTrans()
    if not self._inTrans then
        error('not in a trans')
    else
        local res = self:exec('COMMIT;')
        self._inTrans = false
        return res and true or false
    end
end

function _M:rollback()
    local res = self:exec('ROLLBACK;')
    self._inTrans = false
    return res and true or false
end
 
return _M

