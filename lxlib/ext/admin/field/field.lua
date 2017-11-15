
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        validator = nil,
        config = nil,
        db = nil,
        suppliedOptions = nil,
        userOptions = nil,
        baseDefaults = {
        relationship = false,
        external = false,
        editable = true,
        visible = true,
        setter = false,
        description = '',
        value = '',
        min_value = '',
        max_value = '',
        min_max = false
    },
        defaults = {},
        baseRules = {type = 'required|string', field_name = 'required|string'},
        rules = {}
    }
    
    return oo(this, mt)
end

-- The validator instance.
-- @var \Frozennode\admin\Validator
-- The config interface instance.
-- @var \Frozennode\admin\Config\ConfigInterface
-- The config instance.
-- @var \Illuminate\Database\DatabaseManager
-- The originally supplied options.
-- @var table
-- The options supplied merged into the defaults.
-- @var table
-- The default configuration options.
-- @var table
-- The specific defaults for subclasses to override.
-- @var table
-- The base rules that all fields need to pass.
-- @var table
-- The specific rules for subclasses to override.
-- @var table
-- Create a new Field instance.
-- @param \Frozennode\admin\Validator              validator
-- @param \Frozennode\admin\Config\ConfigInterface config
-- @param \Illuminate\Database\DatabaseManager             db
-- @param table                                            options

function _M:ctor(validator, config, db, options)

    self.validator = validator
    self.config = config
    self.db = db
    self.suppliedOptions = options
end

-- Builds a few basic options.

function _M:build()

    local options = self.suppliedOptions
    --set the title if it doesn't exist
    options['title'] = self.validator:arrayGet(options, 'title', options['field_name'])
    --run the visible property closure if supplied
    local visible = self.validator:arrayGet(options, 'visible')
    if lf.isCallable(visible) then
        options['visible'] = visible(self.config:getDataModel()) and true or false
    end
    --run the editable property's closure if supplied
    local editable = self.validator:arrayGet(options, 'editable')
    if editable and lf.isCallable(editable) then
        options['editable'] = editable(self.config:getDataModel())
    end
    self.suppliedOptions = options
end

-- Validates the supplied options.

function _M:validateOptions()

    --override the config
    self.validator:override(self.suppliedOptions, self:getRules())
    --if the validator failed, throw an exception
    if self.validator:fails() then
        lx.throw(\InvalidArgumentException, "There are problems with your '" .. self.suppliedOptions['field_name'] .. "' field in the " .. self.config:getOption('name') .. ' config: ' .. str.join(self.validator:messages():all(), '. '))
    end
end

-- Turn this item into an table.
-- @return table

function _M:toArray()

    return self:getOptions()
end

-- Fill a model with input data.
-- @param \Illuminate\Database\Eloquent\Model model
-- @param mixed                               input
-- @return table

function _M:fillModel(model, input)

    model.[self:getOption('field_name')] = not input and '' or input
end

-- Sets the filter options for this item.
-- @param table filter

function _M:setFilter(filter)

    self.userOptions['value'] = self:getFilterValue(self.validator:arrayGet(filter, 'value', self:getOption('value')))
    self.userOptions['min_value'] = self:getFilterValue(self.validator:arrayGet(filter, 'min_value', self:getOption('min_value')))
    self.userOptions['max_value'] = self:getFilterValue(self.validator:arrayGet(filter, 'max_value', self:getOption('max_value')))
end

-- Filters a query object given.
-- @param \Illuminate\Database\Query\Builder query
-- @param table                              selects

function _M:filterQuery(query, selects)

    local maxValue
    local minValue
    local model = self.config:getDataModel()
    --if this field has a min/max range, set it
    if self:getOption('min_max') then
        minValue = self:getOption('min_value')
        if minValue then
            query:where(model:getTable() .. '.' .. self:getOption('field_name'), '>=', minValue)
        end
        maxValue = self:getOption('max_value')
        if maxValue then
            query:where(model:getTable() .. '.' .. self:getOption('field_name'), '<=', maxValue)
        end
    end
end

-- Helper function to determine if a filter value should be considered "empty" or not.
-- @param string 	value
-- @return false|string

function _M:getFilterValue(value)

    if value ~= 0 and value ~= '0' and lf.isEmpty(value) or lf.isStr(value) and str.trim(value) == '' then
        
        return false
    else 
        
        return value
    end
end

-- Gets all user options.
-- @return table

function _M:getOptions()

    if lf.isEmpty(self.userOptions) then
        --validate the options and then merge them into the defaults
        self:build()
        self:validateOptions()
        self.userOptions = tb.merge(self:getDefaults(), self.suppliedOptions)
    end
    
    return self.userOptions
end

-- Gets a field's option.
-- @param string key
-- @return mixed

function _M:getOption(key)

    local options = self:getOptions()
    if not tb.has(options, key) then
        lx.throw(\InvalidArgumentException, "An invalid option '{key}' was searched for in the '" .. self.userOptions['field_name'] .. "' field")
    end
    
    return options[key]
end

-- Gets all rules.
-- @return table

function _M:getRules()

    return tb.merge(self.baseRules, self.rules)
end

-- Gets all default values.
-- @return table

function _M:getDefaults()

    return tb.merge(self.baseDefaults, self.defaults)
end

return _M

