
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        config = nil,
        columnFactory = nil,
        fieldFactory = nil,
        columns = nil,
        sort = nil,
        rowsPerPage = 20
    }
    
    return oo(this, mt)
end

-- The config instance.
-- @var \Frozennode\admin\Config\ConfigInterface
-- The validator instance.
-- @var \Frozennode\admin\DataTable\Columns\Factory
-- The validator instance.
-- @var \Frozennode\admin\Fields\Factory
-- The column objects.
-- @var table
-- The sort options.
-- @var table
-- The number of rows per page for this data table.
-- @var int
-- Create a new action DataTable instance.
-- @param \Frozennode\admin\Config\ConfigInterface    config
-- @param \Frozennode\admin\DataTable\Columns\Factory columnFactory
-- @param \Frozennode\admin\Fields\Factory            fieldFactory

function _M:ctor(config, columnFactory, fieldFactory)

    --set the config, and then validate it
    self.config = config
    self.columnFactory = columnFactory
    self.fieldFactory = fieldFactory
end

-- Builds a results table (with results and pagination info).
-- @param \Illuminate\Database\DatabaseManager db
-- @param table                                filters
-- @param int                                  page
-- @param table                                sort    (with 'field' and 'direction' keys)
-- @return table

function _M:getRows(db, filters, page, sort)

    page = page or 1
    --prepare the query
    extract(self:prepareQuery(db, page, sort, filters))
    --run the count query
    local output = self:performCountQuery(countQuery, querySql, queryBindings, page)
    --now we need to limit and offset the rows in remembrance of our dear lost friend paginate()
    query:take(self.rowsPerPage)
    query:skip(self.rowsPerPage * (output['page'] == 0 and output['page'] or output['page'] - 1))
    --parse the results
    output['results'] = self:parseResults(query:get())
    
    return output
end

-- Builds a results table (with results and pagination info).
-- @param \Illuminate\Database\DatabaseManager db
-- @param int                                  page
-- @param table                                sort    (with 'field' and 'direction' keys)
-- @param table                                filters
-- @return table

function _M:prepareQuery(db, page, sort, filters)

    page = page or 1
    --grab the model instance
    local model = self.config:getDataModel()
    --update the sort options
    self:setSort(sort)
    sort = self:getSort()
    --get things going by grouping the set
    local table = model:getTable()
    local keyName = model:getKeyName()
    local query = model:groupBy(table .. '.' .. keyName)
    --get the Illuminate\Database\Query\Builder instance and set up the count query
    local dbQuery = query:getQuery()
    local countQuery = dbQuery:getConnection():table(table):groupBy(table .. '.' .. keyName)
    --run the supplied query filter for both queries if it was provided
    self.config:runQueryFilter(dbQuery)
    self.config:runQueryFilter(countQuery)
    --set up initial table states for the selects
    local selects = {table .. '.*'}
    --set the filters
    self:setFilters(filters, dbQuery, countQuery, selects)
    --set the selects
    dbQuery:select(selects)
    --determines if the sort should have the table prefixed to it
    local sortOnTable = true
    --get the columns
    local columns = self.columnFactory:getColumns()
    --iterate over the columns to check if we need to join any values or add any extra columns
    for _, column in pairs(columns) do
        --if this is a related column, we'll need to add some selects
        column:filterQuery(selects)
        --if this is a related field or
        if (column:getOption('is_related') or column:getOption('select')) and column:getOption('column_name') == sort['field'] then
            sortOnTable = false
        end
    end
    --if the sort is on the model's table, prefix the table name to it
    if sortOnTable then
        sort['field'] = table .. '.' .. sort['field']
    end
    --grab the query sql for later
    local querySql = query:toSql()
    --order the set by the model table's id
    query:orderBy(sort['field'], sort['direction'])
    --then retrieve the rows
    query:getQuery():select(selects)
    --only select distinct rows
    query:distinct()
    --load the query bindings
    local queryBindings = query:getBindings()
    
    return compact('query', 'querySql', 'queryBindings', 'countQuery', 'sort', 'selects')
end

-- Performs the count query and returns info about the pages.
-- @param \Illuminate\Database\Query\Builder countQuery
-- @param string                             querySql
-- @param table                              queryBindings
-- @param int                                page
-- @return table

function _M:performCountQuery(countQuery, querySql, queryBindings, page)

    --grab the model instance
    local model = self.config:getDataModel()
    --then wrap the inner table and perform the count
    local sql = "SELECT COUNT({model:getKeyName()}) AS aggregate FROM ({querySql}) AS agg"
    --then perform the count query
    local results = countQuery:getConnection():select(sql, queryBindings)
    local numRows = lf.isTbl(results[0]) and results[0]['aggregate'] or results[0].aggregate
    page = tonumber(page)
    local last = tonumber(ceil(numRows / self.rowsPerPage))
    
    return {page = page > last and last or page, last = last, total = numRows}
end

-- Sets the query filters when getting the rows.
-- @param mixed                              filters
-- @param \Illuminate\Database\Query\Builder query
-- @param \Illuminate\Database\Query\Builder countQuery
-- @param table                              selects

function _M:setFilters(filters, query, countQuery, selects)

    local fieldObject
    --then we set the filters
    if filters and lf.isTbl(filters) then
        for _, filter in pairs(filters) do
            --get the field object
            fieldObject = self.fieldFactory:findFilter(filter['field_name'])
            --set the filter on the object
            fieldObject:setFilter(filter)
            --filter the query objects, only pass in the selects the first time so they aren't added twice
            fieldObject:filterQuery(query, selects)
            fieldObject:filterQuery(countQuery)
        end
    end
end

-- Parses the results of a getRows query and converts it into a manageable table with the proper rendering.
-- @param Collection rows
-- @return table

function _M:parseResults(rows)

    local arr
    local results = {}
    --convert the resulting set into tables
    for _, item in pairs(rows) do
        --iterate over the included and related columns
        arr = {}
        self:parseOnTableColumns(item, arr)
        --then grab the computed, unsortable columns
        self:parseComputedColumns(item, arr)
        tapd(results, arr)
    end
    
    return results
end

-- Goes through all related columns and sets the proper values for this row.
-- @param \Illuminate\Database\Eloquent\Model item
-- @param table                               outputRow

function _M:parseOnTableColumns(item, outputRow)

    local attributeValue
    if item:__has('presenter') then
        item = item:presenter()
    end
    local columns = self.columnFactory:getColumns()
    local includedColumns = self.columnFactory:getIncludedColumns(self.fieldFactory:getEditFields())
    local relatedColumns = self.columnFactory:getRelatedColumns()
    --loop over both the included and related columns
    for field, col in pairs(tb.merge(includedColumns, relatedColumns)) do
        --            attributeValue = item->getAttribute($field);
        attributeValue = item.[field]
        --if this column is in our objects table, render the output with the given value
        if columns[field] then
            outputRow[field] = {raw = attributeValue, rendered = columns[field]:renderOutput(attributeValue, item)}
        else 
            outputRow[field] = {raw = attributeValue, rendered = attributeValue}
        end
    end
end

-- Goes through all computed columns and sets the proper values for this row.
-- @param \Illuminate\Database\Eloquent\Model item
-- @param table                               outputRow

function _M:parseComputedColumns(item, outputRow)

    local columns = self.columnFactory:getColumns()
    local computedColumns = self.columnFactory:getComputedColumns()
    --loop over the computed columns
    for name, column in pairs(computedColumns) do
        outputRow[name] = {raw = item.[name], rendered = columns[name]:renderOutput(item.[name], item)}
    end
end

-- Sets up the sort options.
-- @param table sort

function _M:setSort(sort)

    sort = sort and lf.isTbl(sort) and sort or self.config:getOption('sort')
    --set the sort values
    self.sort = {field = sort['field'] and sort['field'] or self.config:getDataModel():getKeyName(), direction = sort['direction'] and sort['direction'] or 'desc'}
    --if the sort direction isn't valid, set it to 'desc'
    if not tb.inList({'asc', 'desc'}, self.sort['direction']) then
        self.sort['direction'] = 'desc'
    end
end

-- Gets the sort options.
-- @return table

function _M:getSort()

    return self.sort
end

-- Set the number of rows per page for this data table.
-- @param \Illuminate\Session\Store session
-- @param int                       globalPerPage
-- @param int                       override      //if provided, this will set the session's rows per page value

function _M:setRowsPerPage(session, globalPerPage, override)

    local perPage
    if override then
        perPage = tonumber(override)
        session:put('admin_' .. self.config:getOption('name') .. '_rows_per_page', perPage)
    end
    local perPage = session:get('admin_' .. self.config:getOption('name') .. '_rows_per_page')
    if not perPage then
        perPage = tonumber(globalPerPage)
    end
    self.rowsPerPage = perPage
end

-- Gets the rows per page.
-- @return int

function _M:getRowsPerPage()

    return self.rowsPerPage
end

return _M

