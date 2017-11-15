
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        fieldTypes = {
        key = 'Frozennode\\admin\\Fields\\Key',
        text = 'Frozennode\\admin\\Fields\\Text',
        textarea = 'Frozennode\\admin\\Fields\\Text',
        wysiwyg = 'Frozennode\\admin\\Fields\\Text',
        markdown = 'Frozennode\\admin\\Fields\\Text',
        password = 'Frozennode\\admin\\Fields\\Password',
        date = 'Frozennode\\admin\\Fields\\Time',
        time = 'Frozennode\\admin\\Fields\\Time',
        datetime = 'Frozennode\\admin\\Fields\\Time',
        number = 'Frozennode\\admin\\Fields\\Number',
        bool = 'Frozennode\\admin\\Fields\\Bool',
        enum = 'Frozennode\\admin\\Fields\\Enum',
        image = 'Frozennode\\admin\\Fields\\Image',
        file = 'Frozennode\\admin\\Fields\\File',
        color = 'Frozennode\\admin\\Fields\\Color',
        belongs_to = 'Frozennode\\admin\\Fields\\Relationships\\BelongsTo',
        belongs_to_many = 'Frozennode\\admin\\Fields\\Relationships\\BelongsToMany',
        has_one = 'Frozennode\\admin\\Fields\\Relationships\\HasOne',
        has_many = 'Frozennode\\admin\\Fields\\Relationships\\HasMany'
    },
        relationshipBase = 'Illuminate\\Database\\Eloquent\\Relations\\',
        settingsFieldExclusions = {'key', 'belongs_to', 'belongs_to_many', 'has_one', 'has_many'},
        validator = nil,
        config = nil,
        db = nil,
        filters = {},
        filtersArrays = {},
        editFields = nil,
        editFieldsArrays = nil,
        dataModel = nil
    }
    
    return oo(this, mt)
end

-- The valid field types and their associated classes.
-- @var table
-- The base string for the relationship classes.
-- The base string for the relationship classes.
-- The validator instance.
-- @var \Frozennode\admin\Validator
-- The config interface instance.
-- @var \Frozennode\admin\Config\ConfigInterface
-- The config instance.
-- @var \Illuminate\Database\DatabaseManager
-- The compiled filters objects.
-- @var table
-- The compiled filters tables.
-- @var table
-- The compiled edit fields table.
-- @var table
-- The edit field objects as tables.
-- @var table
-- The edit field data model.
-- @var table
-- Create a new model Config instance.
-- @param \Frozennode\admin\Validator              validator
-- @param \Frozennode\admin\Config\ConfigInterface config
-- @param \Illuminate\Database\DatabaseManager             db

function _M:ctor(validator, config, db)

    self.validator = validator
    self.config = config
    self.db = db
end

-- Makes a field given an table of options.
-- @param mixed name
-- @param mixed options
-- @param bool  loadRelationships //determines whether or not to load the relationships
-- @return mixed

function _M:make(name, options, loadRelationships)

    loadRelationships = lf.needTrue(loadRelationships)
    --make sure the options table has all the proper default values
    options = self:prepareOptions(name, options, loadRelationships)
    
    return self:getFieldObject(options)
end

-- Instantiates a field object.
-- @param table options
-- @param bool  loadRelationships
-- @return Frozennode\admin\Fields\Field

function _M:getFieldObject(options)

    local class = self:getFieldTypeClass(options['type'])
    
    return new('class', self.validator, self.config, self.db, options)
end

-- Gets the class name for a field type.
-- @param string type
-- @return string

function _M:getFieldTypeClass(type)

    return self.fieldTypes[type]
end

-- Sets up an options table with the required base values.
-- @param mixed name
-- @param mixed options
-- @param bool  loadRelationships //determines whether or not to load the relationships
-- @return table

function _M:prepareOptions(name, options, loadRelationships)

    loadRelationships = lf.needTrue(loadRelationships)
    --set the options table to the format we need
    options = self:validateOptions(name, options)
    --make sure the 'title' option is set
    options['title'] = options['title'] and options['title'] or options['field_name']
    options['hint'] = options['hint'] and options['hint'] or ''
    --ensure the type is set and then check that the field type exists
    self:ensureTypeIsSet(options)
    --set the proper relationship options
    self:setRelationshipType(options, loadRelationships)
    --check that the type is a valid field class
    self:checkTypeExists(options)
    
    return options
end

-- Validates an options table item. This could be a string name and table options, or a positive integer name and string options.
-- @param mixed name
-- @param mixed options
-- @return table

function _M:validateOptions(name, options)

    if lf.isStr(options) then
        name = options
        options = {}
    end
    --if the name is not a string or the options is not an table at this point, throw an error because we can't do anything with it
    if not lf.isStr(name) or not lf.isTbl(options) then
        lx.throw(\InvalidArgumentException, 'One of the fields in your ' .. self.config:getOption('name') .. ' configuration file is invalid')
    end
    --in any case, make sure the 'column_name' option is set
    options['field_name'] = name
    
    return options
end

-- Ensures that the type option is set.
-- @param table options

function _M:ensureTypeIsSet(options)

    --if the 'type' option hasn't been set
    if not options['type'] then
        --if this is a model and the field is equal to the primary key name, set it as a key field
        if self.config:getType() == 'model' and options['field_name'] == self.config:getDataModel():getKeyName() then
            options['type'] = 'key'
        else 
            options['type'] = 'text'
        end
    end
end

-- Ensures that a relationship field is valid.
-- @param table options
-- @param bool  loadRelationships

function _M:setRelationshipType(options, loadRelationships)

    --if this is a relationship
    if self.validator:arrayGet(options, 'type') == 'relationship' then
        --get the right key based on the relationship in the model
        options['type'] = self:getRelationshipKey(options['field_name'])
        --if we should load the relationships, set the option
        options['load_relationships'] = loadRelationships and not self.validator:arrayGet(options, 'autocomplete', false)
    end
end

-- Check to see if the type is valid.
-- @param table options

function _M:checkTypeExists(options)

    --if an improper value was supplied
    if not tb.has(self.fieldTypes, options['type']) then
        lx.throw(\InvalidArgumentException, 'The ' .. options['type'] .. ' field type in your ' .. self.config:getOption('name') .. ' configuration file is not valid')
    end
    --if this is a settings page and a field was supplied that is excluded
    if self.config:getType() == 'settings' and tb.inList(self.settingsFieldExclusions, options['type']) then
        lx.throw(\InvalidArgumentException, 'The ' .. options['type'] .. ' field in your ' .. self.config:getOption('name') .. ' settings page cannot be used on a settings page')
    end
end

-- Given a field name, returns the type key or false.
-- @param string field the field type to check
-- @return string|false

function _M:getRelationshipKey(field)

    local model = self.config:getDataModel()
    local invalidArgument = new('\InvalidArgumentException', "The '" .. field .. "' relationship field you supplied for " .. self.config:getOption('name') .. ' is not a valid relationship method name on the supplied Eloquent model')
    --check if the related method exists on the model
    if not model:__has(field) then
        lx.throw(invalidArgument
    end
    --now that we know the method exists, we can determine if it's multiple or single
    local related_model = model:[field]()
    --check if this is a valid relationship object, and return the appropriate key
    if is_a(related_model, self.relationshipBase .. 'BelongsTo') then
        
        return 'belongs_to'
    elseif is_a(related_model, self.relationshipBase .. 'BelongsToMany') then
        
        return 'belongs_to_many'
    elseif is_a(related_model, self.relationshipBase .. 'HasOne') then
        
        return 'has_one'
    elseif is_a(related_model, self.relationshipBase .. 'HasMany') then
        
        return 'has_many'
    else 
        lx.throw(invalidArgument
    end
end

-- Given a field name, this returns the field object from the edit fields table.
-- @param string field
-- @return \Frozennode\admin\Fields\Field

function _M:findField(field)

    local fields = self:getEditFields()
    --return either the Field object or throw an InvalidArgumentException
    if not fields[field] then
        lx.throw(\InvalidArgumentException, 'The ' .. field .. ' field does not exist on the ' .. self.config:getOption('name') .. ' model')
    end
    
    return fields[field]
end

-- Given a field name, this returns the field object from the filters table.
-- @param string field
-- @return \Frozennode\admin\Fields\Field

function _M:findFilter(field)

    local filters = self:getFilters()
    --return either the Field object or throw an InvalidArgumentException
    if not filters[field] then
        lx.throw(\InvalidArgumentException, 'The ' .. field .. ' filter does not exist on the ' .. self.config:getOption('name') .. ' model')
    end
    
    return filters[field]
end

-- Creates the edit fields as Field objects.
-- @param bool loadRelationships //if set to false, no relationship options will be loaded
-- @param bool override          //if set to true, the fields will be re-loaded, otherwise it will use the cached fields
-- @return table

function _M:getEditFields(loadRelationships, override)

    override = override or false
    loadRelationships = lf.needTrue(loadRelationships)
    local fieldObject
    if not sizeof(self.editFields) or override then
        self.editFields = {}
        --iterate over each supplied edit field
        for name, options in pairs(self.config:getOption('edit_fields')) do
            fieldObject = self:make(name, options, loadRelationships)
            self.editFields[fieldObject:getOption('field_name')] = fieldObject
        end
    end
    
    return self.editFields
end

-- Gets the table version of the edit fields objects.
-- @param bool override //this will override the cached version if set to true
-- @return table

function _M:getEditFieldsArrays(override)

    override = override or false
    local return = {}
    for _, fieldObject in pairs(self:getEditFields(true, override)) do
        return[fieldObject:getOption('field_name')] = fieldObject:getOptions()
    end
    --get the key field if this is a model page
    if self.config:getType() == 'model' then
        self:fillKeyField(return)
    end
    
    return return
end

-- Gets the key field for a model for the getEditFieldsArrays.
-- @param table fields
-- @return table

function _M:fillKeyField(fields)

    local keyField
    local model = self.config:getDataModel()
    local keyName = model:getKeyName()
    --add the primary key field, which will be uneditable, but part of the data model
    if self.config:getType() == 'model' and not fields[keyName] then
        keyField = self:make(keyName, {visible = false})
        fields[keyName] = keyField:getOptions()
    end
end

-- Gets the data model given the edit fields.
-- @return table

function _M:getDataModel()

    local dataModel = {}
    local model = self.config:getDataModel()
    for name, options in pairs(self:getEditFieldsArrays()) do
        --if this is a key, set it to 0
        if options['type'] == 'key' then
            dataModel[name] = 0
        else 
            --if this is a collection, convert it to an table
            if is_a(model.[name], 'Illuminate\\Database\\Eloquent\\Collection') then
                dataModel[name] = model.[name]:toArray()
            else 
                dataModel[name] = options['value'] and options['value'] or nil
            end
        end
    end
    
    return dataModel
end

-- Gets the filters for the given model config.
-- @return table

function _M:getFilters()

    local fieldObject
    --get the model's filter fields
    local configFilters = self.config:getOption('filters')
    --make sure that the filters table hasn't been created before and that there are supplied filters in the config
    if not sizeof(self.filters) and configFilters then
        --iterate over the filters and create field objects for them
        for name, filter in pairs(configFilters) do
            fieldObject = self:make(name, filter)
            if fieldObject then
                --the filters table is indexed on the field name and holds the tableed values for the filters
                self.filters[fieldObject:getOption('field_name')] = fieldObject
            end
        end
    end
    
    return self.filters
end

-- Gets the filters table and converts the objects to tables.
-- @return table

function _M:getFiltersArrays()

    if not sizeof(self.filtersArrays) then
        for name, filter in pairs(self:getFilters()) do
            self.filtersArrays[name] = filter:getOptions()
        end
    end
    
    return self.filtersArrays
end

-- Finds a field's options given a field name and a type (filter/edit).
-- @param string field
-- @param string type
-- @return mixed

function _M:getFieldObjectByName(field, type)

    local fields
    local info = false
    --we want to get the correct options depending on the type of field it is
    if type == 'filter' then
        fields = self:getFilters()
    else 
        fields = self:getEditFields()
    end
    --iterate over the fields to get the one for this field value
    for key, val in pairs(fields) do
        if key == field then
            info = val
        end
    end
    
    return info
end

-- Given a model, field, type (filter or edit), and constraints (either int or table), returns an table of options.
-- @param string field
-- @param string type          //either 'filter' or 'edit'
-- @param table  constraints   //an table of ids of the other model's items
-- @param table  selectedItems //an table of ids that are currently selected
-- @param string term          //the search term
-- @return table

function _M:updateRelationshipOptions(field, type, constraints, selectedItems, term)

    --first get the related model and fetch the field's options
    local model = self.config:getDataModel()
    local relatedModel = model:[field]():getRelated()
    local relatedTable = relatedModel:getTable()
    local relatedKeyName = relatedModel:getKeyName()
    local relatedKeyTable = relatedTable .. '.' .. relatedKeyName
    local fieldObject = self:getFieldObjectByName(field, type)
    --if we can't find the field, return an empty table
    if not fieldObject then
        
        return {}
    end
    --make sure we're grouping by the model's id
    local query = relatedModel:newQuery()
    --set up the selects
    query:select({self.db:raw(self.db:getTablePrefix() .. relatedTable .. '.*')})
    --format the selected items into an table
    selectedItems = self:formatSelectedItems(selectedItems)
    --if this is an autocomplete field, check if there is a search term. If not, just return the selected items
    if fieldObject:getOption('autocomplete') and not term then
        if sizeof(selectedItems) then
            self:filterQueryBySelectedItems(query, selectedItems, fieldObject, relatedKeyTable)
            
            return self:formatSelectOptions(fieldObject, query:get())
        else 
            
            return {}
        end
    end
    --applies constraints if there are any
    self:applyConstraints(constraints, query, fieldObject)
    --if there is a search term, limit the result set by that term
    self:filterBySearchTerm(term, query, fieldObject, selectedItems, relatedKeyTable)
    --perform any user-supplied options filter
    local filter = fieldObject:getOption('options_filter')
    filter(query)
    --finally we can return the options
    
    return self:formatSelectOptions(fieldObject, query:get())
end

-- Filters a relationship options query by a search term.
-- @param mixed                                  term
-- @param \Illuminate\Database\Query\Builder     query
-- @param \Frozennode\admin\Fields\Field fieldObject
-- @param table                                  selectedItems
-- @param string                                 relatedKeyTable

function _M:filterBySearchTerm(term, query, fieldObject, selectedItems, relatedKeyTable)

    if term then
        query:where(function(query)
            for _, search in pairs(fieldObject:getOption('search_fields')) do
                query:orWhere(self.db:raw(search), 'LIKE', '%' .. term .. '%')
            end
        end)
        --exclude the currently-selected items if there are any
        if #selectedItems then
            query:whereNotIn(relatedKeyTable, selectedItems)
        end
        --set up the limits
        query:take(fieldObject:getOption('num_options') + #selectedItems)
    end
end

-- Takes the supplied selectedItems mixed value and formats it to a usable table.
-- @param mixed selectedItems
-- @return table

function _M:formatSelectedItems(selectedItems)

    if selectedItems then
        --if this isn't an table, set it up as one
        
        return lf.isTbl(selectedItems) and selectedItems or str.split(selectedItems, ',')
    else 
        
        return {}
    end
end

-- Takes the supplied selectedItems mixed value and formats it to a usable table.
-- @param \Illuminate\Database\Query\Builder     query
-- @param table                                  selectedItems
-- @param \Frozennode\admin\Fields\Field fieldObject
-- @param string                                 relatedKeyTable
-- @return table

function _M:filterQueryBySelectedItems(query, selectedItems, fieldObject, relatedKeyTable)

    query:whereIn(relatedKeyTable, selectedItems)
    --if this is a BelongsToMany and a sort field is set, order it by the sort field
    if fieldObject:getOption('multiple_values') and fieldObject:getOption('sort_field') then
        query:orderBy(fieldObject:getOption('sort_field'))
    else 
        query:orderBy(fieldObject:getOption('name_field'))
    end
end

-- Takes the supplied selectedItems mixed value and formats it to a usable table.
-- @param mixed                                  constraints
-- @param \Illuminate\Database\Query\Builder     query
-- @param \Frozennode\admin\Fields\Field fieldObject
-- @return table

function _M:applyConstraints(constraints, query, fieldObject)

    local otherField
    local otherModel
    local relatedModel
    local model
    local configConstraints = fieldObject:getOption('constraints')
    if sizeof(configConstraints) then
        --iterate over the config constraints
        for key, relationshipName in pairs(configConstraints) do
            --now that we're looping through the constraints, check to see if this one was supplied
            if constraints[key] and constraints[key] and sizeof(constraints[key]) then
                --first we get the other model and the relationship field on it
                model = self.config:getDataModel()
                relatedModel = model:[fieldObject:getOption('field_name')]():getRelated()
                otherModel = model:[key]():getRelated()
                --set the data model for the config
                self.config:setDataModel(otherModel)
                otherField = self:make(relationshipName, {type = 'relationship'}, false)
                --constrain the query
                otherField:constrainQuery(query, relatedModel, constraints[key])
                --set the data model back to the original
                self.config:setDataModel(model)
            end
        end
    end
end

-- Takes an eloquent result table and turns it into an options table that can be used in the UI.
-- @param \Frozennode\admin\Fields\Field   field
-- @param \Illuminate\Database\Eloquent\Collection results
-- @return table

function _M:formatSelectOptions(field, results)

    local return = {}
    for _, m in pairs(results) do
        tapd(return, {id = m:getKey(), text = strval(m.[field:getOption('name_field')])})
    end
    
    return return
end

return _M

