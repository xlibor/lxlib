-- The Column class helps us construct columns from models. It can be used to derive column information from a model, or it can be
-- instantiated to hold information about any given column.


local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'column'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        defaults = {is_related = true, external = true},
        relationshipDefaults = {}
    }
    
    return oo(this, mt)
end

-- The specific defaults for subclasses to override.
-- @var table
-- The relationship-type-specific defaults for the relationship subclasses to override.
-- @var table
-- Builds the necessary fields on the object.

function _M:build()

    local model = self.config:getDataModel()
    local options = self.suppliedOptions
    self.tablePrefix = self.db:getTablePrefix()
    local relationship = model:[options['relationship']]()
    local relevant_model = model
    local selectTable = options['column_name'] .. '_' .. self.tablePrefix .. relationship:getRelated():getTable()
    --set the relationship object so we can use it later
    self.relationshipObject = relationship
    --replace the (:table) with the generated selectTable
    options['select'] = str.replace(options['select'], '(:table)', selectTable)
    self.suppliedOptions = options
end

-- Gets all default values.
-- @return table

function _M:getDefaults()

    local defaults = parent.getDefaults()
    
    return tb.merge(defaults, self.relationshipDefaults)
end

-- Gets all default values.
-- @return table

function _M:getIncludedColumn()

    return {}
end

-- Sets up the existing relationship wheres.
-- @param \Illuminate\Database\Eloquent\Relations\Relation relationship
-- @param string                                           tableAlias
-- @param string                                           pivotAlias
-- @param string                                           pivot
-- @return string

function _M:getRelationshipWheres(relationship, tableAlias, pivotAlias, pivot)

    --get the relationship model
    local relationshipModel = relationship:getRelated()
    --get the query instance
    local query = relationship:getQuery():getQuery()
    --get the connection instance
    local connection = query:getConnection()
    --one element of the relationship query's wheres is always useless (it will say pivot_table.other_id is null)
    --depending on whether or not softdeletes are enabled on the other model, this will be in either position 0
    --or 1 of the wheres table
    array_splice(query.wheres, relationshipModel:__has('getDeletedAtColumn') and 1 or 0, 1)
    --iterate over the wheres to properly alias the columns
    for _, where in pairs(query.wheres) do
        --alias the where columns
        where['column'] = self:aliasRelationshipWhere(where['column'], tableAlias, pivotAlias, pivot)
    end
    local sql = query:toSql()
    local fullQuery = self:interpolateQuery(sql, connection:prepareBindings(query:getBindings()))
    local split = str.split(fullQuery, ' where ')
    
    return split[1] and split[1] or ''
end

-- Aliases an existing where column.
-- @param string column
-- @param string tableAlias
-- @param string pivotAlias
-- @param string pivot
-- @return string

function _M:aliasRelationshipWhere(column, tableAlias, pivotAlias, pivot)

    --first explode the string on "." in case it was given with the table already included
    local split = str.split(column, '.')
    --if the second split item exists, there was a "."
    if split[1] then
        --if the table name is the pivot table, append the pivot alias
        if split[0] == pivot then
            
            return pivotAlias .. '.' .. split[1]
        else 
            
            return tableAlias .. '.' .. split[1]
        end
    else 
        
        return tableAlias .. '.' .. column
    end
end

-- Replaces any parameter placeholders in a query with the value of that
-- parameter.
-- @param string query  //The sql query with parameter placeholders
-- @param table  params //The table of substitution parameters
-- @return string //The interpolated query

function _M:interpolateQuery(query, params)

    local keys = {}
    local values = params
    --build a regular expression for each parameter
    for key, value in pairs(params) do
        if lf.isStr(key) then
            tapd(keys, '/:' .. key .. '/')
        else 
            tapd(keys, '/[?]/')
        end
        if lf.isStr(value) then
            values[key] = "'" .. value .. "'"
        end
        if lf.isTbl(value) then
            values[key] = str.join(value, ',')
        end
        if not value then
            values[key] = 'NULL'
        end
    end
    query = str.rereplace(query, keys, values, 1, count)
    
    return query
end

return _M

