
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str, new = lx.kit()
local use, try, throw = lx.kit2()
local d = lx.def

local sfind, ssub, slen, slower = string.find, string.sub, string.len, string.lower
local tconcat = table.concat

local pub = require('lxlib.db.pub')
local dbInit = require('lxlib.db')
local dbCommon = require('lxlib.db.common')

local Paginator = lx.use('paginator')

function _M:new(dboOrList, dbType)

    local this = {
        dbType            = dbType or 'mysql',
        sql                = '',
        hasRs            = false,
        testMode        = false, 
        rowAsList        = false,
        eventsDef        = {},
        _useWriteLdo    = false
    }

    local dbo
    if dboOrList.__cls then
        dbo = dboOrList
        this._dbo = dbo
        this._baseColumns = dbo._columns
    else
        if #dboOrList == 0 then

        end

        dbo = dboOrList[1]
        this._dbo = dbo
        this._baseColumns = dbo._fullColumns
        
        local dbos, columnsList = {}, {}
        local tblName, eColumns
        for _, v in pairs(dboOrList) do
            tblName = v._tblName
            if not tblName then
                error('hi')
            end
            dbos[tblName] = v
            eColumns = v._fullColumns
            columnsList[tblName] = eColumns
        end

        this._dbos = dbos
        this._columnsList = columnsList
    end
 
    setmetatable(this, mt)

    return this
end

function _M:ctor()

    self:initTableJoins()
end

function _M:page(currPage, pageSize)
    
    currPage = tonumber(currPage)
    if not currPage then currPage = 1 end
    if currPage == 0 then currPage = 1 end
    pageSize = tonumber(pageSize)
    if not pageSize then pageSize = 10 end
    if pageSize == 0 then pageSize = 10 end
    
    self._limitField = nil
    self._currPage = currPage
    self._perPage = pageSize
    
    return self
end

function _M:begin()

    local conn = self:_initConn()
    if conn then
        conn:begin()
    end
end

function _M:commit()

    local conn = self:_initConn()
    if conn then
        conn:commit()
    end
end

function _M:rollback()

    local conn = self:_initConn()
    if conn then
        conn:rollback()
    end
end

function _M:_initConn()

    local conn = self.conn
    if conn then
        return conn
    else
        error('no conn')
    end
end

function _M.cf(fieldName,...)

    local cvtField = dbInit.sqlConvertField(fieldName, ...)
    
    return cvtField
end

function _M:exp(expression)
    
    local cvtField = dbInit.sqlConvertField()
    cvtField:setExpression(expression)

    return cvtField
end

function _M:baseTable()

    local dbo = self._dbo
    if dbo then
        return dbo._tblName
    end
end

function _M:tableAs(tableAlias)

    local dbo = self._dbo
    if type(tableAlias) == 'string' then

        tableAlias = {[dbo._tblName] = tableAlias}
    end

    local tables = self:initSelectTables(dbo)
 
    if tables:count() > 0 then
        for k, v in pairs(tableAlias) do
            for _, table in ipairs(tables.items) do
                if k == table.name then
                    table.alias = v
                end
            end
        end
    end

    return self
end

function _M:from(dbo, ...)

    local args = {...}
 
    local tables = self:initSelectTables(dbo)
    local dbos = self._dbos or {}
        
    if #args == 0 then

    else
        for _, v in pairs(args) do
            tables:add(v._tblName)
        end
    end

    return self
end

function _M:_addDboToList(dbo)

    local tblName = dbo._tblName
    local dbos = self._dbos or {}

    if not dbos[tblName] then
        dbos[tblName] = dbo
        local columnsList = self._columnsList or {}
        local columns = {}
        local columnName

        if dbo.__cls ~= '__cls' then
            for k, v in pairs(dbo) do
                columnName = v[2]
                if columnName then
                    columns[k] = tblName..'.'..columnName
                else
                    columns[k] = tblName..'.'..k
                end
            end
        end
        columns._tblName = tblName
        columnsList[tblName] = columns
        self._dbos = dbos
        self._columnsList = columnsList
    end
end

function _M:_baseJoin(factor, joinCdtFields, joinType)

    local join, dboFactor
    local factorType = type(factor)
 
    if factorType == 'string' then
        local dbef = app:get('db.entityFactory')
        dboFactor = dbef:makeDbo(factor)
    else
        dboFactor = factor
    end
    
    join = self:_dboJoin(joinType, dboFactor, joinCdtFields)
    self._ormJoin = join

    return self._ormJoin
end

function _M:join(factor, joinCdtFields)

    return self:_baseJoin(factor, joinCdtFields, d.innerJoin)
end

function _M:innerJoin(factor, joinCdtFields)

    return self:_baseJoin(factor, joinCdtFields,d.innerJoin)
end

function _M:leftJoin(factor, joinCdtFields)

    return self:_baseJoin(factor, joinCdtFields,d.leftJoin)
end

function _M:rightJoin(factor, joinCdtFields)

    return self:_baseJoin(factor, joinCdtFields,d.rightJoin)
end

function _M:outerJoin(factor, joinCdtFields)

    return self:_baseJoin(factor, joinCdtFields,d.outerJoin)
end

function _M:_dboJoin(joinType, dboFactor, joinCdtFields)

    local tDbo

    if not self._dbos or not next(self._dbos) then
        self:_addDboToList(self._dbo)
    end

    self:_addDboToList(dboFactor)
    
    local dboPrimary = self._dbo
    
    self:initTableJoins()

    local tableJoin = self:_getTableJoin(dboFactor._tblName)
    tableJoin.joinType = joinType
    self._tableJoins:addJoin(tableJoin)
    
    local dboJoin = dbInit.sqlJoin()
    dboJoin.tableJoin = tableJoin
    
    if joinCdtFields then
        joinCdtFields.tableJoin = tableJoin
        joinCdtFields:setAllOn()
    end
    
    return dboJoin
end

function _M:_getTableJoin(factorName)
    
    local primaryTable = dbInit.sqlSelectTable(self._dbo._tblName)
    local factorTable = dbInit.sqlSelectTable(factorName)

    local tableJoin = dbInit.sqlSelectTableJoin(primaryTable, nil, factorTable)
    
    return tableJoin
end

function _M:fireEvent(event, sqlObj)

    return app:fire(self, event, sqlObj)
end

function _M:insert(...)

    if self:fireEvent('beforeSave') then return end
 
    if self:fireEvent('beforeInsert') then return end
 
    local dbo = self._dbo

    local strSql
    local args = {...}
    local fieldValues
    local fName, fValue, fDef, fDataType
    local argType
    local dbType = self.dbType
    local tableName = dbo._tblName
    local sqlInsert = dbInit.sqlInsert(tableName)
    local castValue = pub.sqlCastValue
    local fields, values, p1, p2

    if not self._fieldValues then
        self._fieldValues = dbInit.sqlFieldValues()
    end
    
    fieldValues = self._fieldValues
 
    if #args > 0 then
        if #args == 1 then 
            p1 = args[1]
            if type(p1) == 'table' then
                self:set(p1)
            end
            fieldValues = self._fieldValues
        elseif #args == 2 then
            local p1, p2 = args[1], args[2]
            if type(p1) ~= 'table' or type(p2) ~= 'table' then
                error('args for insert must be table ')
            else
                if #p1 ~= #p2 then
                    error('both length of fields and values must equal ')
                end

                local tblDef = dbo.tblDef

                if tblDef then
                    for i, v in ipairs(p1) do
                        fName = v; fValue = p2[i]
                        fDef = tblDef[fName]
                        if fDef then
                            fDataType = fDef.dt
                            if fDataType>0 then
                                fValue = castValue(fValue,fDataType,dbType)
                                fieldValues:add(fName, fValue)
                            end
                        end
                    end
                else
                    for i, v in ipairs(p1) do
                        fName = v; fValue = p2[i]
                        fieldValues:add(fName, fValue)
                    end
                end
            end   
        else
        
        end
    end
    
    sqlInsert.fields = fieldValues
    
    local style = self.style
    if style then
        if style == 'insert' then
            style = 0
        elseif style == 'replace' then
            style = 1
        end
        sqlInsert.style = style
    end
 
    if self:fireEvent('aroundSave', sqlInsert) then return end
 
    if self:fireEvent('aroundInsert', sqlInsert) then return end
 
    self.sql = sqlInsert:sql(dbType)
 
    if not self.testMode then
        self:_initConn()
        local res = self.conn:exec(self.sql)
        if res then
            local insertId = res.insert_id
            self.conn.lastInsertId = insertId
        end
        self:fireEvent('afterInsert')
 
        self:fireEvent('afterSave')
 
    end
    
    return true
end

function _M:insertGetId(...)

    if self:insert(...) then
        return self.conn.lastInsertId
    else
        return 0
    end

end

function _M:inserts(fieldsList, asOneSql)
    
    if type(fieldsList) ~= 'table' then return end  
    if #fieldsList == 0 then return end
    
    if not asOneSql then
        for _, fields in ipairs(fieldsList) do
            self:reset()
            self:set(fields)
            self:insert()
        end
    end
    
    return true
end

function _M:update(...)
 
    if self:fireEvent('beforeSave') then return end
 
    if self:fireEvent('beforeUpdate') then return end

    local strSql
    local args = {...}
    local fieldValues 
    local argType
    local dbType = self.dbType
    local tableName = self._dbo._tblName
    local sqlUpdate = dbInit.sqlUpdate(tableName)

    if #args > 0 then
        self:set(...)
    end
    
    if not self._fieldValues then
        error('have not set fieldValues')
    end

    fieldValues = self._fieldValues
    sqlUpdate.fields = fieldValues
    sqlUpdate.conditions = self._conditions
 
    if self:fireEvent('aroundSave', sqlUpdate) then return end
 
    if self:fireEvent('aroundUpdate', sqlUpdate) then return end
 
    self.sql = sqlUpdate:sql(dbType)
    
    if not self.testMode then
        self:_initConn()
        local res = self.conn:exec(self.sql)
 
        self:fireEvent('afterUpdate')
 
        self:fireEvent('afterSave')
 
    end
    
    return true
end

function _M:delete()
 
    if self:fireEvent('beforeDelete') then return end
 
    local strSql
    local dbType = self.dbType
    local tableName = self._dbo._tblName
    local sqlDelete = dbInit.sqlDelete(tableName)

    sqlDelete.conditions = self._conditions
    self.sql = sqlDelete:sql(dbType)
 
    if self:fireEvent('aroundDelete', sqlDelete) then return end
 
    if not self.testMode then
        self:_initConn()
        local res = self.conn:exec(self.sql)
 
        self:fireEvent('afterDelete')
    end
    
    return true
end

function _M:truncate()

    local dbo = self._dbo
    local tableName = dbo._tblName
    local dbType = self.dbType

    if not self.testMode then
        local conn = self:_initConn()
        local res = conn:exec(
            'truncate table ' .. pub.sqlWrapName(tableName, dbType))

        return res
    else
        return true
    end
end

function _M:findOne(...)

    self:limit(1)
    local args = {...}
    if #args > 0 then 
        local p1 =args[1]
        local p1Type = type(p1)
        if p1Type ~= 'table' then 
            local pk = self._dbo.primaryKey
            if pk then
                self:where(pk, d.eq, p1)
            end
        else
            self:where(p1)
        end
    end
    
    return self:find()
end

function _M:find(condition, ...)
     
    local pkName = 'id'
    if type(condition) ~= 'table' then 
        local pk = self._dbo.primaryKey
        if pk then
            pkName = pk
        end
        self:where(pkName, '=', condition)
    else
        self:where(condition)
    end

    return self:first(...)
end

function _M:first(...)

    local results = self:limit(1):get(...)
    if results and #results > 0 then
        return results[1]
    end
end

function _M:toSql(callback)

    local testMode = self.testMode
    self:test(true)

    local sql
    if callback then
        callback(self)
    else
        self:get()
    end

    sql = self.sql
    self:test(testMode)

    return sql
end

function _M:get(...)

    local res

    if self:fireEvent('beforeSelect') then return end
 
    self.hasRs = false
    
    local args = {...}
    if #args > 0 then
        self:sel(...)
    end
    
    local dbType = self.dbType
    local sqlSelect = dbInit.sqlSelect()

    local tables = self:initSelectTables()
    local selectFields = self:initSelectFields()

    local dbos = self._dbos or {}
    local dbo

    sqlSelect.tables = tables
    sqlSelect.fields = selectFields
    sqlSelect.orderByFields = self._orderByFields
    sqlSelect.groupByFields = self._groupByFields
    self:initSelectLimit()
    sqlSelect.limitField = self._limitField
    sqlSelect.conditions = self._conditions
    if self._tableJoins then
        sqlSelect.tables.tableJoins = self._tableJoins
    end
 
    if self:fireEvent('aroundSelect', sqlSelect) then return end
 
    if not self.testMode then 
        self:_initConn()
        
        local currPage, pageSize = self._currPage, self._perPage
        if currPage then
            local countAnyFs = dbInit.sqlSelectFields()
            countAnyFs:add(nil, nil, 'totalNum', d.count)
            sqlSelect.fields = countAnyFs
            -- if sqlSelect.orderByFields then
            --     sqlSelect.orderByFields = nil
            -- end
            local tsql = sqlSelect:sql(dbType)
 
            local trs = self.conn:exec(tsql)
            if trs then
                local trs1 = trs[1]
                local totalNum = 0
                if sqlSelect.groupByFields then
                    totalNum = #trs
                else
                    if trs1 then
                        totalNum = tonumber(trs1.totalNum) or 0
                    else
                        totalNum = 0
                    end
                end
                local pageCount, ifModover = 0, false
                if totalNum > 0 then
                    pageCount,ifModover = math.modf(totalNum / pageSize)
                    if ifModover > 0 then pageCount = pageCount + 1 end
                    if currPage > pageCount then currPage = pageCount end
                    local offset = (currPage - 1) * pageSize
                    if pageSize > totalNum then pageSize = totalNum end
                    local tLimit = dbInit.sqlSelectLimitField(offset, pageSize)
 
                    sqlSelect.limitField = tLimit
                    sqlSelect.fields = selectFields
                    if self._orderByFields then
                        sqlSelect.orderByFields = self._orderByFields
                    end
                    self.sql = sqlSelect:sql(dbType)
                else
                    pageCount = 0; currPage = 0
                end
                self._currPage = currPage
                self._total = totalNum
                self._pageCount = pageCount
                self._perPage = pageSize
            end
        else
            self.sql = sqlSelect:sql(dbType)
        end
        
        if slen(self.sql) > 0 then
            res = self.conn:select(self.sql)
        else
            res = {}
        end

        if #res > 0 then self.hasRs = true end
    else
        self.sql = sqlSelect:sql(dbType)
    end
     
    self.rs = res

    self:fireEvent('afterSelect')
     
    return self.rs
end

function _M.__:initSelectFields()

    if not self._selectFields then
        self._selectFields = dbInit.sqlSelectFields()
    end

    return self._selectFields
end

function _M:selectedCount()

    local selects = self:initSelectFields()

    return #selects.items
end

function _M:joinedCount()

    local joins = self:initTableJoins()

    return #joins.items
end

function _M.__:initTableJoins()

    if not self._tableJoins then
        self._tableJoins = dbInit.sqlSelectTableJoins()
    end

    return self._tableJoins
end

function _M.__:initSelectTables(dbo)

    local selectTables = self._selectTables
    if not selectTables then
        selectTables = dbInit.sqlSelectTables()
        self._selectTables = selectTables
    end

    if selectTables:count() == 0 then
        if not dbo then
            dbo = self._dbo
        end
        selectTables:add(dbo._tblName)
    end

    return selectTables
end

function _M:set(...)

    local strSql
    local args = {...}
    if #args == 0 then 
        return self
        -- error('no args in lxorm->query->set()')
    end

    local fieldValues 
    local fName, fValue, fDef,fDataType
    local strSql,argType,p1Type
    local dbType = self.dbType
    local tableName = self._dbo._tblName
    local castValue = pub.sqlCastValue
    local dbo = self._dbo
    
    if not self._fieldValues then
        self._fieldValues = dbInit.sqlFieldValues()
    end
    fieldValues = self._fieldValues
 
    local p1 = args[1]
    p1Type = type(p1)

    if p1Type == 'string' then
        local tmp = {}
        for i,v in ipairs(args) do
            if math.mod(i,2) == 0 then
                tmp[args[i-1]] = v
            end
        end
        p1 = tmp
        p1Type = 'table'
    end
    
    if p1Type == 'table' then
        if p1.__cls == 'col' then
            p1 = p1.values
        end

        local tblDef = dbo.tblDef

        if tblDef then 
            for fName, fValue in pairs(p1) do
                fDef = tblDef[fName]
                if fDef then
                    fDataType = fDef.dt
                    if fDataType > 0 then
                        fValue = castValue(fValue,fDataType,dbType)
                        fieldValues:add(fName, fValue)
                    end
                end
            end
        else
            for fName, fValue in pairs(p1) do
                fieldValues:add(fName, fValue)
            end
        end
    else
    
    end

    return self
end

function _M:select(...)

    self:addSelect({...})
    
    return self
end

_M.sel = _M.select

function _M:addSelect(args)

    local selectFields = self:initSelectFields()
    local argType

    for _, v in ipairs(args) do 
        argType = type(v)
        if argType == 'string' then
            selectFields:add(v)
        elseif argType == 'table' then
            if v.__cls then
                selectFields:add(v)
            else
                selectFields:add(v[1], nil, v[2] ,v[3], v[4])
            end
        end 
    end 

    return self
end

_M.pick = _M.addSelect

function _M:and_(...)

    local wheres = self:initWheres()
    wheres:addLO('and')
    self:where(...)
    
    return self
end

function _M:orWhere(...)

    local wheres = self:initWheres()
    wheres:addLO('or')
    self:where(...)
    
    return self
end

_M.or_ = _M.orWhere

function _M:getWheres()

    return self:initWheres()
end

function _M.__:initWheres()

    if not self._conditions then
        self._conditions = dbInit.sqlConditions()
    end

    return self._conditions
end

function _M:where(...)

    local args, argsLen = lf.getArgs(...)
    
    if #args == 0 then 
        return self
    end
    
    local p1, p2, p3 = args[1], args[2], args[3]
    
    if argsLen == 3 and not p3 then
        throw('invalidColumnValueException', p1, p2)
    elseif argsLen == 2 then
        p3 = p2; p2 = '='
    end

    local p1Type = type(p1)
    local newTopCdts
    
    local wheres = self:getWheres()
    
    if p1Type == 'string' then
        p3 = self:castValue(p1, p3)
          wheres:add(p1, p2, p3)
      elseif p1Type == 'table' then
        local clsName = p1.__cls
        if clsName == 'sqlConditions' then
            p1 = pub.checkNestCdts(p1) 
            if p1._needNot then 
                newTopCdts = dbInit.sqlConditions()
                newTopCdts:addLO('not')
                newTopCdts:addConditions(p1)
                wheres:addConditions(newTopCdts)
            else
                wheres:addConditions(p1)
            end
        elseif clsName == 'sqlCondition' then
            if p1._needNot then 
                wheres:addLO('not')
            end

            wheres:addCondition(p1)
        elseif clsName == 'sqlConvertField' then
            wheres:add(p1, p2, p3)
        elseif clsName == nil then
            if #p1 > 0 then
                p2 = p1[2]
                p1 = p1[1]
                wheres:add(p1, '=', p2)
            elseif next(p1) then
                newTopCdts = dbInit.sqlConditions()
                for k,v in pairs(p1) do
                    v = self:castValue(k, v)
                    newTopCdts:add(k, d.eq,v)
                end

                wheres:addConditions(newTopCdts)
            else
                -- error('condition param is empty table')
            end
        end
      end
    
    return self
end

_M.wh = _M.where

function _M:whereIn(column, values)

    return self:where(column, 'in', values)
end

function _M:mergeWheres(cdts)

    if cdts:count() > 0 then
        self:where(cdts)
    end
end

function _M:columns(tblName)

    local columns 
    if tblName then
        local csl = self._columnsList
        columns = csl[tblName]
    else
        columns = self._baseColumns
    end
    
    return columns
end

function _M:fill()

    local obj
    local rs = self.rs
    if rs then
        obj = rs[1]
    end
    
    return obj
end

function _M:w(...)
    
    local where

    self:initWheres()
    
    local args = {...}
    if #args == 0 then
        error('w() or w{} expression invalid, may some fieldvalue is nil')
    end

    local p1, p2, p3 = args[1], args[2], args[3]
    local p1Type = type(p1)
    
    if p1Type == 'string' then 
        p3 = self:castValue(p1, p3)
        local cdt = dbInit.sqlCondition(p1, p2, p3)

        return cdt
    elseif p1Type == 'table' then
        local cdts = dbInit.sqlConditions()
        if p1.__cls then  
            local cdt = dbInit.sqlCondition(p1, p2, p3)

            return cdt
        else
            if not next(p1) then
                error('condition param is empty table')
            end
            for k,v in pairs(p1) do
                v = self:castValue(k, v)
                cdts:add(k, d.eq, v)
            end
        end

        return cdts
    end
end

function _M.__:castValue(fName, fValue)

    local fDef, fDataType
    local dbo = self._dbo
    local i,j = sfind(fName, '%.')
    
    if not self._dbos then return fValue end

    if i then 
        local tblName
        tblName = ssub(fName, 1, i-1)
        fName = ssub(fName, i+1)
        dbo = self._dbos[tblName]
    end
    
    if dbo then
        if dbo.tblDef then
            fDef = dbo.tblDef[fName]
            if fDef then
                fDataType = fDef.dt
                if fDataType > 0 then
                    fValue = pub.sqlCastValue(fValue,fDataType,self.dbType)
                end
            end
        end
    end
    
    return fValue
end
 
function _M:groupBy(...)

    local args = {...}
    local groupBy = dbInit.sqlSelectGroupByFields()
    for _,v in pairs(args) do 
        groupBy:add(v)
    end
    self._groupByFields = groupBy 

    return self
end

_M.group = _M.groupBy

function _M:orderBy(...)

    local args, len = lf.getArgs(...)
    if len == 0 then

        return self
    end

    local orderBy = dbInit.sqlSelectOrderByFields()

    if len == 2 then
        local p1, p2 = args[1], args[2]

        if type(p2) == 'string' then
            p2 = slower(p2)
            if p2 == 'asc' or p2 == 'desc' then
                orderBy:add(p1, nil, p2)
                self._orderByFields = orderBy 

                return self
            end
        end
    end

    local argType
    for _,v in ipairs(args) do 
        argType = type(v)
        if argType == 'string' then
            orderBy:add(v)
        elseif argType == 'table' then
            if v.__cls then 
                orderBy:add(v)
            else
                orderBy:add(v[1], nil, v[2] ,v[3])
            end
        end 
    end

    self._orderByFields = orderBy 

    return self
end

_M.order = _M.orderBy

function _M:take(value)

    self._limit = value

    return self
end

function _M:skip(value)

    self._offset = value

    return self
end

function _M:limit(p1, p2)

    local offset = (p1 and p2) and p1 or nil
    local rows = (p1 and p2) and p2 or p1

    self._offset = offset
    self._limit = rows

    return self
end

function _M:initSelectLimit()

    local limit = self._limit
    local offset = self._offset

    if limit or offset then
        local limitField = dbInit.sqlSelectLimitField()
        limitField.offset = offset
        limitField.rows = limit

        self._limitField = limitField 
    end
end

function _M:reset(returnBaseColumns)
    
    self.sql = ''
    self.style = nil
    self.rowAsList = false
    self._conditions = nil
    self._fieldValues = nil
    self._groupByFields = nil
    self._orderByFields = nil
    self._limitField = nil
    self._selectFields = nil
    self._selectTables = nil
    self.res = {}

    self._limit = nil
    self._offset = nil
    self._perPage = nil
    self._currPage = nil
    self._total = nil
    self._pageCount = nil
    
    if returnBaseColumns then
        return self:columns()
    end
end

function _M:rsCount()

    local ret = 0
    local rs = self.rs
    if rs then
        ret = #rs
    end
    
    return ret
end

function _M:execute(sql)

    self.sql = sql
    self:_initConn()
    local res = self.conn:exec(self.sql, self.rowAsList)

    return res
end

_M.exec = _M.execute

function _M:test(value)

    value = lf.needTrue(value)

    self.testMode = value

    return self
end

function _M:max(column)

    return self:aggregate('max', column)
end

function _M:min(column)

    return self:aggregate('min', column)
end

function _M:sum(column)

    return self:aggregate('sum', column)
end

function _M:avg(column)

    return self:aggregate('avg', column)
end

_M.average = _M.avg

function _M:count(column)

    column = column or '*'
    local ret = self:aggregate('count', column)

    return tonumber(ret) or 0 
end

function _M:aggregate(funcType, column)

    self._selectFields = nil
    self:select({column, 'aggregate', funcType})

    local ret
    local rs = self:get()

    if next(rs) then
        ret = rs[1]

        return tonumber(ret.aggregate) or 0
    else
        return 0
    end
end

function _M:pluck(column, key)

    local results
    if key then
        results = self:get(column)
    else
        results = self:get(column, key)
    end

    return tb.pluck(results,
        self:stripTableForPluck(column),
        self:stripTableForPluck(key)
    )
end

function _M.__:stripTableForPluck(column)

    if column then
        column = tb.last(str.split(column, '.'))
    end

    return column
end

function _M:newQuery(table)

    local conn = self.conn

    return conn:table(table)
end

function _M:getSql()

    return self.sql
end

function _M:lockForUpdate()

    return self
end

function _M:useWriteLdo()

    self._useWriteLdo = true

    return self
end

function _M:selectSub(query, as)

    local callback
    if lf.isFun(query) then
        callback = query
        query = self:newQuery()
        callback(query)
    end

    if lf.isA(query, self.__cls) then
        query = query:toSql()
    else
        lx.throw('invalidArgumentException')
    end

    return self:selectRaw('(' .. query .. ') as ' .. as)
end

function _M:selectRaw(raw)

    local expression = self:exp(raw)
    
    return self:select(expression)
end

function _M:whereRaw(raw)

    local expression = self:exp(raw)
    
    return self:where(expression)
end

function _M:increment(column, amount, extra)

    amount = amount or 1
    if not lf.isNum(amount) then
        lx.throw('invalidArgumentException', 'Non-numeric value passed to increment method.')
    end

    self:set(column, self.cf(column):make('%s + ' .. amount))
    if extra then
        self:set(extra)
    end

    return self:update()
end

_M.incr = _M.increment

function _M:decrement(column, amount, extra)

    amount = amount or 1
    if not lf.isNum(amount) then
        lx.throw('invalidArgumentException', 'Non-numeric value passed to decrement method.')
    end

    self:set(column, self.cf(column):make('%s - ' .. amount))
    if extra then
        self:set(extra)
    end

    return self:update()
end

_M.decr = _M.decrement

function _M:paginate(perPage, columns, pageName, page)

    pageName = pageName or 'page'
    columns = columns or {}
    perPage = perPage or 15
    page = page or Paginator.resolveCurrentPage(pageName)
    self:page(page, perPage)
    self:get()
    local total = self._total

    local results = self.rs or {}

    return new('lengthAwarePaginator',
        results, total, perPage, page,
        {path = Paginator.resolveCurrentPath(), pageName = pageName}
    )
end

_M.paging = _M.paginate

function _M:simplePaginate(perPage, columns, pageName, page)

    pageName = pageName or 'page'
    columns = columns or {'*'}
    perPage = perPage or 15
    page = page or Paginator.resolveCurrentPage(pageName)
    self:skip((page - 1) * perPage):take(perPage + 1)
    
    return new('paginator' ,self:get(columns), perPage, page, {path = Paginator.resolveCurrentPath(), pageName = pageName})
end

function _M:forPageAfterId(perPage, lastId, column)

    column = column or 'id'
    lastId = lastId or 0
    perPage = perPage or 15
    self.orders = Col(self.orders):reject(function(order)
        
        return order.column == column
    end):values():all()
    
    return self:where(column, '>', lastId)
        :orderBy(column, 'asc')
        :take(perPage)
end

function _M:getCountForPagination(columns)

    local dbType = self.dbType
    local sqlSelect = dbInit.sqlSelect()

    local tables = self:initSelectTables()

    sqlSelect.tables = tables
    sqlSelect.orderByFields = self._orderByFields
    sqlSelect.groupByFields = self._groupByFields
    sqlSelect.conditions = self._conditions
    if self._tableJoins then
        sqlSelect.tables.tableJoins = self._tableJoins
    end
    local countAnyFs = dbInit.sqlSelectFields()
    countAnyFs:add(nil, nil, 'totalNum', d.count)
    sqlSelect.fields = countAnyFs

    local conn = self:_initConn()

    local tsql = sqlSelect:sql(dbType)
    local totalNum = 0
    local trs = conn:exec(tsql)
    if trs then
        local trs1 = trs[1]
        if sqlSelect.groupByFields then
            totalNum = #trs
        else
            if trs1 then
                totalNum = tonumber(trs1.totalNum) or 0
            end
        end
    end

    return totalNum
end

function _M:isNull(column)

    self:where(column, '=', ngx.null)

    return self
end

function _M:notNull(column)

    self:where(column, '<>', ngx.null)

    return self
end

function _M:_clone_(newObj)

end

return _M

