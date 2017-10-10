
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'relationship'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        relationshipDefaults = {external = false}
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
    options['table'] = relatedModel:getTable()
    options['column'] = relatedModel:getKeyName()
    options['foreign_key'] = relationship:getForeignKey()
    self.suppliedOptions = options
end

-- Fill a model with input data.
-- @param \Illuminate\Database\Eloquent\Model model
-- @param mixed                               input
-- @return table

function _M:fillModel(model, input)

    model.[self:getOption('foreign_key')] = input ~= 'false' and input or nil
    model:__unset(self:getOption('field_name'))
end

-- Filters a query object with this item's data given a model.
-- @param \Illuminate\Database\Query\Builder query
-- @param table                              selects

function _M:filterQuery(query, selects)

    --run the parent method
    parent.filterQuery(query, selects)
    --if there is no value, return
    if not self:getOption('value') then
        
        return
    end
    query:where(self:getOption('foreign_key'), '=', self:getOption('value'))
end

return _M

