
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'field'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        defaults = {
        relationship = true,
        external = true,
        name_field = 'name',
        options_sort_field = false,
        options_sort_direction = 'ASC',
        table = '',
        column = '',
        foreign_key = false,
        multiple_values = false,
        options = {},
        self_relationship = false,
        autocomplete = false,
        num_options = 10,
        search_fields = {},
        constraints = {},
        load_relationships = false
    },
        relationshipDefaults = {},
        rules = {
        name_field = 'string',
        sort_field = 'string',
        options_sort_field = 'string',
        options_sort_direction = 'string',
        num_options = 'integer|min:0',
        search_fields = 'array',
        options_filter = 'callable',
        constraints = 'array'
    }
    }
    
    return oo(this, mt)
end

-- The specific defaults for subclasses to override.
-- @var table
-- The relationship-type-specific defaults for the relationship subclasses to override.
-- @var table
-- The specific rules for subclasses to override.
-- @var table
-- Builds a few basic options.

function _M:build()

    parent.build()
    local options = self.suppliedOptions
    local model = self.config:getDataModel()
    local relationship = model:[options['field_name']]()
    --set the search fields to the name field if none exist
    local searchFields = self.validator:arrayGet(options, 'search_fields')
    local nameField = self.validator:arrayGet(options, 'name_field', self.defaults['name_field'])
    options['search_fields'] = lf.isEmpty(searchFields) and {nameField} or searchFields
    --determine if this is a self-relationship
    options['self_relationship'] = relationship:getRelated():getTable() == model:getTable()
    --make sure the options filter is set up
    options['options_filter'] = self.validator:arrayGet(options, 'options_filter') or function()
    end
    --set up and check the constraints
    self:setUpConstraints(options)
    --load up the relationship options
    self:loadRelationshipOptions(options)
    self.suppliedOptions = options
end

-- Sets up the constraints for a relationship field if provided. We do this so we can assume later that it will just work.
-- @param table options

function _M:setUpConstraints(options)

    local validConstraints
    local constraints = self.validator:arrayGet(options, 'constraints')
    local model = self.config:getDataModel()
    --set up and check the constraints
    if sizeof(constraints) then
        validConstraints = {}
        --iterate over the constraints and only include the valid ones
        for field, rel in pairs(constraints) do
            --check if the supplied values are strings and that their methods exist on their respective models
            if lf.isStr(field) and lf.isStr(rel) and model:__has(field) then
                validConstraints[field] = rel
            end
        end
        options['constraints'] = validConstraints
    end
end

-- Loads the relationship options and sets the options option if load_relationships is true.
-- @param table options

function _M:loadRelationshipOptions(options)

    local relationshipItems
    local optionsSortField
    local query
    local optionsSortDirection
    --if we want all of the possible items on the other model, load them up, otherwise leave the options empty
    local items = {}
    local model = self.config:getDataModel()
    local relationship = model:[options['field_name']]()
    local relatedModel = relationship:getRelated()
    if self.validator:arrayGet(options, 'load_relationships') then
        optionsSortField = self.validator:arrayGet(options, 'options_sort_field')
        --if a sort field was supplied, order the results by it
        if optionsSortField then
            optionsSortDirection = self.validator:arrayGet(options, 'options_sort_direction', self.defaults['options_sort_direction'])
            query = relatedModel:orderBy(self.db:raw(optionsSortField), optionsSortDirection)
        else 
            query = relatedModel:newQuery()
        end
        --run the options filter
        options['options_filter'](query)
        --get the items
        items = query:get()
    relationshipItems = relationship:get()elseif relationshipItems then
        items = relationshipItems
        -- if no related items exist, add default item, if set in options
        if #items == 0 and tb.has(options, 'value') then
            items = relatedModel:where(relatedModel:getKeyName(), '=', options['value']):get()
        end
    end
    --map the options to the options property where table('id': [key], 'text': [nameField])
    local nameField = self.validator:arrayGet(options, 'name_field', self.defaults['name_field'])
    local keyField = relatedModel:getKeyName()
    options['options'] = self:mapRelationshipOptions(items, nameField, keyField)
end

-- Maps the relationship options to an table with 'id' and 'text' keys.
-- @param table  items
-- @param string nameField
-- @param string keyField
-- @return table

function _M:mapRelationshipOptions(items, nameField, keyField)

    local result = {}
    for _, option in pairs(items) do
        tapd(result, {id = option.[keyField], text = strval(option.[nameField])})
    end
    
    return result
end

-- Gets all default values.
-- @return table

function _M:getDefaults()

    local defaults = parent.getDefaults()
    
    return tb.merge(defaults, self.relationshipDefaults)
end

return _M

