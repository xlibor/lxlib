
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'hasOneOrMany'
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
-- Fill a model with input data.
-- @param \Illuminate\Database\Eloquent\Model model
-- @param mixed                               input
-- @return table

function _M:fillModel(model, input)

    local sortField
    local relatedObject
    -- input is an table of all foreign key IDs
    --
    -- model is the model for which the above answers should be associated to
    local fieldName = self:getOption('field_name')
    input = input and str.split(input, ',') or {}
    local relationship = model:[fieldName]()
    -- get the plain foreign key so we can set it to null:
    local fkey = relationship:getPlainForeignKey()
    local relatedObjectClass = get_class(relationship:getRelated())
    -- first we "forget all the related models" (by setting their foreign key to null)
    for _, related in pairs(relationship:get()) do
        related.[fkey] = nil
        -- disassociate
        related:save()
    end
    -- now associate new ones: (setting the correct order as well)
    local i = 0
    for _, foreign_id in pairs(input) do
        relatedObject = lf.call(relatedObjectClass .. '::find', foreign_id)
        sortField = self:getOption('sort_field')
        if sortField then
            relatedObject.[sortField] = i
            i = i + 1
        end
        relationship:save(relatedObject)
    end
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

return _M

