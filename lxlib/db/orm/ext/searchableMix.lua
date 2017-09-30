
local lx, _M = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()
local slower = string.lower

function _M:ctor()

end

-- Creates the search scope.
-- @param   orm.query       q
-- @param   string          search
-- @param   float|null      threshold
-- @param   boolean         entireText
-- @param   boolean         entireTextOnly
-- @return  orm.query

function _M:scopeSearch(q, search, threshold, entireText, entireTextOnly)

    entireTextOnly = entireTextOnly or false
    entireText = entireText or false
    
    return self:scopeSearchRestricted(q, search, nil, threshold, entireText, entireTextOnly)
end

function _M:scopeSearchRestricted(q, search, restriction, threshold, entireText, entireTextOnly)

    local t
    entireTextOnly = entireTextOnly or false
    entireText = entireText or false

    local query = q:__clone()

    query:select(self:getTable() .. '.*')
    self:makeJoins(query)
    if not search then
        
        return q
    end

    local words = self:getWords(search)

    local queries
    local selects = {}

    local relevance_count = 0

    for column, relevance in pairs(self:getColumns()) do
        relevance_count = relevance_count + relevance
        if not entireTextOnly then
            queries = self:getSearchQueriesForColumn(query, column, relevance, words)
        else
            queries = {}
        end
        if entireText and #words > 1 or entireTextOnly then

            tapd(queries, self:getSearchQuery(query, column, relevance, {search}, 50, '', ''))
            tapd(queries, self:getSearchQuery(query, column, relevance, {search}, 30, '%', '%'))
        end
        for _, select in ipairs(queries) do
            tapd(selects, select)
        end
    end

    self:addSelectsToQuery(query, selects)
    -- Default the threshold if no value was passed.
    if not threshold then
        threshold = relevance_count / 4
    end
    self:filterQueryWithRelevance(query, selects, threshold)
    self:makeGroupBy(query)
    local clone_bindings = query:getAllBindings({'select', 'having'})
    query:resetWheres()

    if lf.isCallable(restriction) then
        query = restriction(query)
    end

    q:fromRaw('(' .. query:toSql() .. ') as ' .. query:baseTable())

    return q
end

function _M.__:getWords(search)

    search = slower(str.trim(search))

    local matches = str.rematchAll(
        search, [[(?:")((?:\\\\.|[^\\\\"])*)(?:")|(\S+)]]
    )

    local words = {}
    for _, m in ipairs(matches) do
        t = m[1]
        if t and t ~= '' then
            tapd(words, t)
        end

        for i = 2, #m do
            t = m[i]
            if t and t ~= '' then
                tapd(words, t)
            end
        end
    end

    return words
end
-- Returns database driver Ex: mysql, pgsql, sqlite.
-- @return table

function _M.__:getDatabaseDriver()

    local key = self.connection or app:conf('db.default')
    
    return app:conf('db.connections.' .. key .. '.driver')
end

-- Returns the search columns.
-- @return table

function _M.__:getColumns()

    local columns
    local prefix
    local driver
    if tb.has(self.searchable, 'columns') then
        driver = self:getDatabaseDriver()
        prefix = app:conf('db.connections.' .. driver .. '.prefix')
        columns = {}
        for column, priority in pairs(self.searchable['columns']) do
            columns[prefix .. column] = priority
        end
        
        return columns
    else 
        
        return DB.connection():getSchemaBuilder():getColumns(self.table)
    end
end

-- Returns whether or not to keep duplicates.
-- @return table

function _M.__:getGroupBy()

    if tb.has(self.searchable, 'groupBy') then
        
        return self.searchable['groupBy']
    end
    
    return false
end

-- Returns the table columns.
-- @return table

function _M:getTableColumns()

    return self.searchable['table_columns']
end

-- Returns the tables that are to be joined.
-- @return table

function _M.__:getJoins()

    return tb.get(self.searchable, 'joins', {})
end

-- Adds the sql joins to the query.
-- @param orm.query query

function _M.__:makeJoins(query)

    for table, keys in pairs(self:getJoins()) do
        query:leftJoin(table, function(join)
            join:on(keys[0], '=', keys[1])
            if tb.has(keys, 2) and tb.has(keys, 3) then
                join:where(keys[2], '=', keys[3])
            end
        end)
    end
end

-- Makes the query not repeat the results.
-- @param orm.query query

function _M.__:makeGroupBy(query)

    local groupBy = self:getGroupBy()
    if groupBy then
        query:groupBy(groupBy)
    else 
        driver = self:getDatabaseDriver()
        if driver == 'sqlsrv' then
            columns = self:getTableColumns()
        else 
            columns = self:getTable() .. '.' .. self.primaryKey
        end
        query:groupBy(columns)
        joins = tb.keys(self:getJoins())
        for column, relevance in pairs(self:getColumns()) do
            tb.map(joins, function(join)
                if str.contains(column, join) then
                    query:groupBy(column)
                end
            end)
        end
    end
end

-- Puts all the select clauses to the main query.
-- @param orm.query query
-- @param table selects

function _M.__:addSelectsToQuery(query, selects)

    query:selectRaw('max(' .. str.join(selects, ' + ') .. ') as relevance')
end

-- Adds the relevance filter to the query.
-- @param orm.query query
-- @param table selects
-- @param float relevance_count

function _M.__:filterQueryWithRelevance(query, selects, relevance_count)

    local comparator = self:getDatabaseDriver() ~= 'mysql' and str.join(selects, ' + ') or 'relevance'
    relevance_count = str.formatNumber(relevance_count, 2, '.', '')
    query:havingRaw(comparator .. ' >= ' .. relevance_count)
    query:orderBy('relevance', 'desc')
    -- add bindings to postgres
end

-- Returns the search queries for the specified column.
-- @param orm.query query
-- @param string column
-- @param float relevance
-- @param table words
-- @return table

function _M.__:getSearchQueriesForColumn(query, column, relevance, words)

    local queries = {}
    tapd(queries, self:getSearchQuery(query, column, relevance, words, 15))
    tapd(queries, self:getSearchQuery(query, column, relevance, words, 5, '', '%'))
    tapd(queries, self:getSearchQuery(query, column, relevance, words, 1, '%', '%'))
    
    return queries
end

-- Returns the sql string for the given parameters.
-- @param orm.query query
-- @param string column
-- @param string relevance
-- @param table words
-- @param string compare
-- @param float relevance_multiplier
-- @param string pre_word
-- @param string post_word
-- @return string

function _M.__:getSearchQuery(query, column, relevance, words, relevance_multiplier, pre_word, post_word)

    post_word = post_word or ''
    pre_word = pre_word or ''
    local like_comparator = self:getDatabaseDriver() == 'pgsql' and 'ILIKE' or 'LIKE'
    local cases = {}
    for _, word in ipairs(words) do
        tapd(cases, self:getCaseCompare(column, like_comparator, relevance * relevance_multiplier, pre_word .. word .. post_word))
    end

    return str.join(cases, ' + ')
end

-- Returns the comparison string.
-- @param string column
-- @param string compare
-- @param float relevance
-- @return string

function _M.__:getCaseCompare(column, compare, relevance, value)

    local field
    if self:getDatabaseDriver() == 'pgsql' then
        field = "LOWER(" .. column .. ") " .. compare .. " '" .. value .. "'"
        
        return '(case when ' .. field .. ' then ' .. relevance .. ' else 0 end)'
    end
    column = str.replace(column, '%.', '`.`')
    local field = "LOWER(`" .. column .. "`) " .. compare .. " '" .. value .. "'"

    return '(case when ' .. field .. ' then ' .. relevance .. ' else 0 end)'
end

-- Adds the bindings to the query.
-- @param orm.query query
-- @param table bindings

function _M.__:addBindingsToQuery(query, bindings)

    local type
    local count = self:getDatabaseDriver() ~= 'mysql' and 2 or 1
    for i = 1, count do
        for _, binding in pairs(bindings) do
            type = i == 1 and 'select' or 'having'

            query:addBinding(type, binding)
        end
    end
end

return _M

