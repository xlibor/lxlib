
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'relationship'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        relationshipDefaults = {column2 = '', multiple_values = true, sort_field = false}
    }
    
    return oo(this, mt)
end

-- The relationship-type-specific defaults for the relationship subclasses to override.
-- @var table
-- Builds a few basic options.

function _M:build()

    parent.build()
    local options = self.suppliedOptions
    local model = self.config:getDataModel()
    local relationship = model:[options['field_name']]()
    local relatedModel = relationship:getRelated()
    options['table'] = relationship:getTable()
    options['column'] = relationship:getForeignKey()
    options['column2'] = relationship:getOtherKey()
    options['foreign_key'] = relatedModel:getKeyName()
    self.suppliedOptions = options
end

-- Fill a model with input data.
-- @param \Illuminate\Database\Eloquent\Model model
-- @param mixed                               input
-- @return table

function _M:fillModel(model, input)

    input = input and str.split(input, ',') or {}
    local fieldName = self:getOption('field_name')
    local relationship = model:[fieldName]()
    local sortField = self:getOption('sort_field')
    --if this field is sortable, delete all the old records and insert the new ones one at a time
    if sortField then
        --first delete all the old records
        relationship:detach()
        --then re-attach them in the correct order
        for i, item in pairs(input) do
            relationship:attach(item, {sortField = i})
        end
    else 
        --elsewise the order doesn't matter, so use sync
        relationship:sync(input)
    end
    --unset the attribute on the model
    model:__unset(fieldName)
end

-- Filters a query object with this item's data.
-- @param \Illuminate\Database\Query\Builder query
-- @param table                              selects

function _M:filterQuery(query, selects)

    --run the parent method
    parent.filterQuery(query, selects)
    --get the values
    local value = self:getOption('value')
    local table = self:getOption('table')
    local column = self:getOption('column')
    local column2 = self:getOption('column2')
    --if there is no value, return
    if not value then
        
        return
    end
    local model = self.config:getDataModel()
    --if the table hasn't been joined yet, join it
    if not self.validator:isJoined(query, table) then
        query:join(table, model:getTable() .. '.' .. model:getKeyName(), '=', column)
    end
    --add where clause
    query:whereIn(column2, value)
    --add having clauses
    query:havingRaw('COUNT(DISTINCT ' .. query:getConnection():getTablePrefix() .. column2 .. ') = ' .. #value)
    --add select field
    if selects and not tb.inList(selects, column2) then
        tapd(selects, column2)
    end
end

-- Constrains a query by a given set of constraints.
-- @param \Illuminate\Database\Eloquent\Builder query
-- @param \Illuminate\Database\Eloquent\Model   relatedModel
-- @param string                                constraint

function _M:constrainQuery(query, relatedModel, constraint)

    --if the column hasn't been joined yet, join it
    if not self.validator:isJoined(query, self:getOption('table')) then
        query:join(self:getOption('table'), relatedModel:getTable() .. '.' .. relatedModel:getKeyName(), '=', self:getOption('column2'))
    end
    query:where(self:getOption('column'), '=', constraint)
end

return _M

