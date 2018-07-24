
local lx, _M, mt = oo{ 
    _cls_ = '',
    _bond_ = 'connectionBond',
    _auto_ = {
        tablePrefix     = true,
        dbName          = true,
    }
}

local app, lf, tb, str = lx.kit()
local try, throw = lx.try, lx.throw
local sgsub = string.gsub
local fmt = string.format
local dbInit = lx.db

function _M:new(ldo, dbName, tablePrefix, config)

    local this = {
        ldo                 = ldo,
        transactions        = 0,
        queryLog            = {},
        loggingQueries      = false,
        pretending          = false,
        dbName              = dbName or '',
        tablePrefix         = tablePrefix or '',
        config              = config or {},
        lastInsertId        = 0,
    }

    return oo(this, mt)
end

function _M:table(...)

    local args = {...}
    local len = #args
    local dbo, tableName, columns
    local q, cdt

    local dbef = app:get('db.entityFactory')

    if len == 1 then
        tableName = args[1]
        dbo = dbef:makeDbo(tableName)
        q = self:query(dbo)
        cdt = function(...)
            return q.w(q, ...)
        end
        columns = dbo._columns

        return q, columns, cdt
    elseif len > 1 then
        local dbos, retArgs = {}, {}
        for _, tableName in ipairs(args) do
            dbo = dbef:makeDbo(tableName, true)
            tapd(dbos, dbo)
            tapd(retArgs, dbo._fullColumns)
        end
        q = self:query(dbos)
        cdt = function(...)
            return q.w(q, ...)
        end
        tapd(retArgs, cdt)

        return q, unpack(retArgs)
    end
end

function _M:query(dboOrList)

    local q = app:make('db.query', dboOrList, self.config.driver)

    q.conn = self
 
    return q
end

function _M:raw(value)

    return app:make('db.queryExpression', value)
end

function _M:selectOne(query, bindings)

    local records = self:select(query, bindings)
    if tb.count(records) > 0 then 
        return records[1]
    end
end

function _M:select(query, bindings, useReadLdo)

    if type(useReadLdo) == 'nil' then 
        useReadLdo = true
    end

    return self:run(query, bindings, function(query, bindings)
        if self.pretending then 
            return {}
        end

        query = self:prepareBindings(query, bindings)

        local result = self:getLdoForSelect(useReadLdo):query(query)

        return result
    end)
end

function _M:run(query, bindings, callback)

    local result

    self:reconnectIfMissingConnection()

    local t1 = lf.time(true, true)

    try(function()

        result = self:runQueryCallback(query, bindings, callback)
    end)
    :catch(function(e)

        result = self:tryAgainIfCausedByLostConnection(
            e, query, bindings, callback
        )
    end):run()

    local cost = lf.time(true, true) - t1

    self:logQuery(query, cost)

    return result
end

function _M:insert(query, bindings)

    return self:exec(query, bindings)
end

function _M:update(query, bindings)

    return self:exec(query, bindings)
end

function _M:delete(query, bindings)

    return self:exec(query, bindings)
end

function _M:statement(query, bindings)

    return self:run(query, bindings, function(query, bindings)
         
        if self.pretending then 
            return true
        end

        query = self:prepareBindings(query, bindings)

        local result = self:getLdo():exec(query)

        if result then
            return result.affectedRows
        else
            return false
        end
    end)
end

_M.stmt = _M.statement

function _M:execute(query, bindings)
    
    return self:run(query, bindings, function(query, bindings)

        if self.pretending then 
            return {}
        end

        query = self:prepareBindings(query, bindings)
 
        return self:getLdo():exec(query)
    end)
end

_M.exec = _M.execute

function _M:execRows(query, bindings)

end

function _M:prepareBind(bindings)

end

function _M:transLevel()

end

function _M:beginTrans()

end

function _M:disconnect()

    self:setLdo(nil)
    self:setReadLdo(nil)
end

function _M:reconnect()

    local reconnector = self.reconnector
    if type(reconnector) == 'function' then 

        return reconnector(self)
    end

    throw('logicException', 'lost connection and no reconnector available.')
end

function _M:unprepared()

end

function _M:prepareBindings(query, bindings)

    if bindings then        
        if #bindings > 0 then
            query = sgsub(query, '%?', '%%s')
            query = fmt(query, unpack(bindings))
        elseif next(bindings) then
            local value, valueType
            query = sgsub(query, "%$(%w+)", function(var)
                value = bindings[var]
                valueType = type(value)
                if valueType == 'string' then 
                    value = "'" .. value .. "'"
                end

                return value
            end)
        end
    end

    return query
end

function _M:transaction(callback)

    self:beginTransaction()
    local result

    try(function()
        result = callback(self)
        self:commit()
    end)
    :catch(function(e)
        self:rollback()
        throw(e)
    end)
    :run()

    return result
end

_M.trans = _M.transaction

function _M:beginTransaction()

    local transactions = self.transactions
    transactions = transactions + 1
    self.transactions = transactions

    if transactions == 1 then
        self:getLdo():beginTransaction()
    elseif transactions > 1 then

    end

end

_M.begin = _M.beginTransaction

function _M:commit()
 
    if self.transactions == 1 then
        self:getLdo():commit()
    end

    self.transactions = self.transactions - 1

end

function _M:rollback()

    local transLevel = self.transactions
    if transLevel == 1 then
        self:getLdo():rollback()
    end

    transLevel = transLevel - 1 
    if transLevel < 0 then transLevel = 0 end

    self.transactions = transLevel
end

function _M:transactionLevel()

    return self.transactions
end

_M.transLevel = _M.transactionLevel

function _M:pretend(callback)
    
    local loggingQueries = self.loggingQueries
    self:enableQueryLog()
    self.pretending = true
    self.queryLog = {}
    callback(self)
    self.pretending = false
    self.loggingQueries = loggingQueries

    return self.queryLog
end

function _M:logQuery(query, time)

    local events = self.events
    if events then
        events:fire('queryExecuted', query, time, self)
    end

    if self.loggingQueries then
        tapd(self.queryLog, {query = query, time = time})
    end
end

function _M:listen(callback)

    local events = self.events
    if events then
        events:listen('queryExecuted', callback)
    end
end

function _M:getLdo()
    
    local ldo = self.ldo

    if type(ldo) == 'function' then
        self.ldo = ldo()
    end

    return self.ldo
end

function _M:getReadLdo()

    if self.transactions >= 1 then 
        return self:getLdo()
    end

    return self.readLdo or self:getLdo()
end

function _M:setLdo(ldo)

    if self.transactions >= 1 then
        throw('runtimeException', "can't swap ldo instance while within transaction.")
    end

    self.ldo = ldo

    return self
end

function _M:setReadLdo(ldo)

    self.readLdo = ldo

    return self
end

function _M:setReconnector(reconnector)

    self.reconnector = reconnector

    return self
end

function _M:getName()

    return self:getConfig('name')
end

function _M:getConfig(option)

    return tb.get(self.config, option)
end

function _M:getDriverName()

    return self:getConfig('driver')
end

_M.getDbType = _M.getDriverName


function _M:enableQueryLog()

    self.loggingQueries = true
end

function _M:disableQueryLog()

    self.loggingQueries = false
end

function _M.__:fireConnectionEvent()

end

function _M.__:runQueryCallback(query, bindings, callback)

    local result

    lx.try(function()

        result = callback(query, bindings)
    end)
    :catch(function(e)

        throw('queryException', query, bindings or {}, e)
    end)
    :run()

    return result
end

function _M.__:tryAgainIfCausedByLostConnection(e, query, binds, callback)

    if self:causedByLostConnection(e:getPrev()) then 
        self:reconnect()

        return self:runQueryCallback(query, bindings, callback)
    end

    throw(e)
end

function _M.__:causedByLostConnection(e)

end

function _M.__:reconnectIfMissingConnection()

    if not self:getLdo() or not self:getReadLdo() then 
        self:reconnect()
    end
end

function _M.__:getLdoForSelect(useReadLdo)

    if useReadLdo then 
        return self:getReadLdo()
    else
        return self:getLdo()
    end
end

function _M:getSchemaBuilder()

    local sb = app:make('db.schema', self)

    return sb
end

function _M:getGrammar()

    local commonGrammar = dbInit.common(self:getDbType())

    return commonGrammar
end

_M.grammar = _M.getGrammar

return _M

