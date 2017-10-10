
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        validator = nil,
        config = nil,
        db = nil,
        options = nil,
        suppliedOptions = nil,
        baseDefaults = {
        relationship = false,
        sortable = true,
        select = false,
        output = '(:value)',
        sort_field = nil,
        nested = {},
        is_related = false,
        is_computed = false,
        is_included = false,
        external = false,
        belongs_to_many = false,
        visible = true
    },
        defaults = {},
        baseRules = {
        column_name = 'required|string',
        title = 'string',
        relationship = 'string',
        select = 'required_with:relationship|string'
    },
        rules = {},
        relationshipObject = nil,
        tablePrefix = ''
    }
    
    return oo(this, mt)
end

-- The validator instance.
-- @var \Frozennode\Administrator\Validator
-- The config instance.
-- @var \Frozennode\Administrator\Config\ConfigInterface
-- The config instance.
-- @var \Illuminate\Database\DatabaseManager
-- The options table.
-- @var table
-- The originally-supplied options table.
-- @var table
-- The default configuration options.
-- @var table
-- The specific defaults for subclasses to override.
-- @var table
-- The base rules that all fields need to pass.
-- @var table
-- The specific rules for subclasses to override.
-- @var table
-- The immediate relationship object for this column.
-- @var Relationship
-- The table prefix.
-- @var string
-- Create a new action Factory instance.
-- @param \Frozennode\Administrator\Validator              validator
-- @param \Frozennode\Administrator\Config\ConfigInterface config
-- @param \Illuminate\Database\DatabaseManager             db
-- @param table                                            options

function _M:ctor(validator, config, db, options)

    self.config = config
    self.validator = validator
    self.db = db
    self.suppliedOptions = options
end

-- Validates the supplied options.

function _M:validateOptions()

    --override the config
    self.validator:override(self.suppliedOptions, self:getRules())
    --if the validator failed, throw an exception
    if self.validator:fails() then
        lx.throw(\InvalidArgumentException, "There are problems with your '" .. self.suppliedOptions['column_name'] .. "' column in the " .. self.config:getOption('name') .. ' model: ' .. str.join(self.validator:messages():all(), '. '))
    end
end

-- Builds the necessary fields on the object.

function _M:build()

    local model = self.config:getDataModel()
    local options = self.suppliedOptions
    self.tablePrefix = self.db:getTablePrefix()
    --set some options-based defaults
    options['title'] = self.validator:arrayGet(options, 'title', options['column_name'])
    options['sort_field'] = self.validator:arrayGet(options, 'sort_field', options['column_name'])
    --if the supplied item is an accessor, make this unsortable for the moment
    if model:__has(camel_case('get_' .. options['column_name'] .. '_attribute')) and options['column_name'] == options['sort_field'] then
        options['sortable'] = false
    end
    local select = self.validator:arrayGet(options, 'select')
    --however, if this is not a relation and the select option was supplied, str_replace the select option and make it sortable again
    if select then
        options['select'] = str.replace(select, '(:table)', self.tablePrefix .. model:getTable())
    end
    --now we do some final organization to categorize these columns (useful later in the sorting)
    if model:__has(camel_case('get_' .. options['column_name'] .. '_attribute')) or select then
        options['is_computed'] = true
    else 
        options['is_included'] = true
    end
    --run the visible property closure if supplied
    local visible = self.validator:arrayGet(options, 'visible')
    if lf.isCallable(visible) then
        options['visible'] = visible(self.config:getDataModel()) and true or false
    end
    self.suppliedOptions = options
end

-- Adds selects to a query.
-- @param table selects

function _M:filterQuery(selects)

    local select = self:getOption('select')
    if select then
        tapd(selects, self.db:raw(select .. ' AS ' .. self.db:getQueryGrammar():wrap(self:getOption('column_name'))))
    end
end

-- Gets all user options.
-- @return table

function _M:getOptions()

    --make sure the supplied options have been merged with the defaults
    if lf.isEmpty(self.options) then
        --validate the options and build them
        self:validateOptions()
        self:build()
        self.options = tb.merge(self:getDefaults(), self.suppliedOptions)
    end
    
    return self.options
end

-- Gets a field's option.
-- @param string key
-- @return mixed

function _M:getOption(key)

    local options = self:getOptions()
    if not tb.has(options, key) then
        lx.throw(\InvalidArgumentException, "An invalid option was searched for in the '" .. options['column_name'] .. "' column")
    end
    
    return options[key]
end

-- Takes a column output string and renders the column with it (replacing '(:value)' with the column's field value).
-- @param value string	$value
-- @param \Illuminate\Database\Eloquent\Model item
-- @return string

function _M:renderOutput(value, item)

    local output = self:getOption('output')
    if lf.isCallable(output) then
        
        return output(value, item)
    end
    
    return str.replace(output, '(:value)', value)
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

