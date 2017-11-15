-- The Model Config class helps retrieve a model's configuration and provides a reliable pointer for these items.


local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'configBase',
    _bond_ = 'configInterface'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        type = 'model',
        defaults = {
        filters = {},
        query_filter = nil,
        permission = true,
        action_permissions = {
        create = true,
        delete = true,
        update = true,
        view = true
    },
        actions = {},
        global_actions = {},
        sort = {},
        form_width = 285,
        link = nil,
        rules = false,
        messages = false
    },
        model = nil,
        rules = {
        title = 'required|string',
        single = 'required|string',
        model = 'required|string|eloquent',
        columns = 'required|array|not_empty',
        edit_fields = 'required|array|not_empty',
        filters = 'array',
        query_filter = 'callable',
        permission = 'callable',
        action_permissions = 'array',
        actions = 'array',
        global_actions = 'array',
        sort = 'array',
        form_width = 'integer',
        link = 'callable',
        rules = 'array',
        messages = 'array'
    }
    }
    
    return oo(this, mt)
end

-- The config type.
-- @var string
-- The default configuration options.
-- @var table
-- An instance of the Eloquent model object for this model.
-- @var \Illuminate\Database\Eloquent\Model
-- The rules table.
-- @var table
-- Fetches the data model for a config.
-- @return \Illuminate\Database\Eloquent\Model

function _M:getDataModel()

    local name
    if not self.model then
        name = self:getOption('model')
        self.model = new('name')
    end
    
    return self.model
end

-- Sets the data model for a config.
-- @param \Illuminate\Database\Eloquent\Model model

function _M:setDataModel(model)

    self.model = model
end

-- Gets a model given an id.
-- @param id    id
-- @param table fields
-- @param table columns
-- @return \Illuminate\Database\Eloquent\Model

function _M:getModel(id, fields, columns)

    id = id or 0
    local model = self:getDataModel()
    --if we're getting an existing model, we'll want to first get the edit fields without the relationships loaded
    local originalModel = model
    --get the model by id
    model = model:find(id)
    model = model and model or originalModel
    --if the model exists, load up the existing related items
    if model.exists then
        self:setExtraModelValues(fields, model)
    end
    
    return model
end

-- Fills a model with the data it needs before being sent back to the user.
-- @param table                               fields
-- @param \Illuminate\Database\Eloquent\Model model

function _M:setExtraModelValues(fields, model)

    --make sure the relationships are loaded
    for name, field in pairs(fields) do
        if field:getOption('relationship') then
            self:setModelRelationship(model, field)
        end
        --if this is a setter field, unset it
        if field:getOption('setter') then
            model:__unset(name)
        end
    end
end

-- Fills a model with the necessary relationship values for a field.
-- @param \Illuminate\Database\Eloquent\Model    model
-- @param \Frozennode\admin\Fields\Field field

function _M:setModelRelationship(model, field)

    local keyName
    local autocompleteArray
    local relationsArray
    --if this is a belongsToMany, we want to sort our initial values
    local relatedItems = self:getModelRelatedItems(model, field)
    local name = field:getOption('field_name')
    local multipleValues = field:getOption('multiple_values')
    local nameField = field:getOption('name_field')
    local autocomplete = field:getOption('autocomplete')
    local options = field:getOption('options')
    --get all existing values for this relationship
    if relatedItems then
        --the table that holds all the ids of the currently-related items
        relationsArray = {}
        --the id-indexed table that holds all of the select option data for a relation.
        --this holds the currently-related items and all of the available options
        autocompleteArray = {}
        --iterate over the items
        for _, item in pairs(relatedItems) do
            keyName = item:getKeyName()
            --if this is a mutliple-value type (i.e. HasMany, BelongsToMany), make sure this is an table
            if multipleValues then
                tapd(relationsArray, item.[keyName])
            else 
                model:setAttribute(name, item.[keyName])
            end
            --if this is an autocomplete field, we'll need to provide an table of tables with 'id' and 'text' indexes
            if autocomplete then
                autocompleteArray[item.[keyName]] = {id = item.[keyName], text = item.[nameField]}
            end
        end
        --if this is a BTM, set the relations table to the property that matches the relationship name
        if multipleValues then
            model.[name] = relationsArray
        end
        --set the options attribute
        model:setAttribute(name .. '_options', options)
        --unset the relationships so we only get back what we need
        model.relationships = {}
        --set the autocomplete table
        if autocomplete then
            model:setAttribute(name .. '_autocomplete', autocompleteArray)
        end
    else 
        model.[name] = {}
    end
end

-- Fills a model with the necessary relationship values.
-- @param \Illuminate\Database\Eloquent\Model    model
-- @param \Frozennode\admin\Fields\Field field
-- @return \Illuminate\Database\Eloquent\Collection

function _M:getModelRelatedItems(model, field)

    local sortField
    local name = field:getOption('field_name')
    if field:getOption('multiple_values') then
        sortField = field:getOption('sort_field')
        --if a sort_field is provided, use it, otherwise sort by the name field
        if sortField then
            
            return model:[name]():orderBy(sortField):get()
        else 
            
            return model:[name]():get()
        end
    else 
        
        return model:[name]():get()
    end
end

-- Updates a model with the latest permissions, links, and fields.
-- @param \Illuminate\Database\Eloquent\Model       model
-- @param \Frozennode\admin\Fields\Factory  fieldFactory
-- @param \Frozennode\admin\Actions\Factory actionFactory
-- @return \Illuminate\Database\Eloquent\Model

function _M:updateModel(model, fieldFactory, actionFactory)

    --set the data model to the active model
    self:setDataModel(model:find(model:getKey()))
    local link = self:getModelLink()
    --include the item link if one was supplied
    if link then
        model:setAttribute('admin_item_link', link)
    end
    --set up the model with the edit fields new data
    model:setAttribute('admin_edit_fields', fieldFactory:getEditFieldsArrays(true))
    --set up the new actions data
    model:setAttribute('admin_actions', actionFactory:getActionsOptions(true))
    model:setAttribute('admin_action_permissions', actionFactory:getActionPermissions(true))
    
    return model
end

-- Saves the model.
-- @param \Illuminate\Http\Request input
-- @param table                    fields
-- @param table                    actionPermissions
-- @param int                      id
-- @return mixed //string if error, true if success

function _M:save(input, fields, actionPermissions, id)

    id = id or 0
    local model = self:getDataModel():find(id)
    --fetch the proper model so we don't have to deal with any extra attributes
    if not model then
        model = self:getDataModel()
    end
    --make sure the user has the proper permissions
    if model.exists then
        if not actionPermissions['update'] then
            
            return 'You do not have permission to save this item'
        end
    elseif not actionPermissions['update'] or not actionPermissions['create'] then
        
        return 'You do not have permission to create this item'
    end
    --fill the model with our input
    self:fillModel(model, input, fields)
    --validate the model
    local data = model.exists and model:getDirty() or model:getAttributes()
    local validation_data = tb.merge(data, self:getRelationshipInputs(input, fields))
    local rules = self:getModelValidationRules()
    rules = model.exists and tb.cross(rules, validation_data) or rules
    local messages = self:getModelValidationMessages()
    local validation = self:validateData(validation_data, rules, messages)
    --if a string was kicked back, it's an error, so return it
    if lf.isStr(validation) then
        
        return validation
    end
    --save the model
    model:save()
    --save the relationships
    self:saveRelationships(input, model, fields)
    --set/update the data model
    self:setDataModel(model)
    
    return true
end

-- Prepare a model for saving given a post input table.
-- @param \Illuminate\Database\Eloquent\Model model
-- @param \Illuminate\Http\Request            input
-- @param table                               fields

function _M:fillModel(model, input, fields)

    local type
    --run through the edit fields to see if we need to unset relationships or uneditable fields
    for name, field in pairs(fields) do
        if not field:getOption('external') and field:getOption('editable') then
            field:fillModel(model, input:get(name, nil))
        elseif name ~= model:getKeyName() then
            model:__unset(name)
        end
    end
    --loop through the fields again to unset any setter fields
    for name, field in pairs(fields) do
        type = field:getOption('type')
        if field:getOption('setter') and type ~= 'password' or type == 'password' and lf.isEmpty(model.[name]) then
            model:__unset(name)
        end
    end
end

-- Gets the validation rules for this model.
-- @return table

function _M:getModelValidationRules()

    local optionsRules = self:getOption('rules')
    --if the 'rules' option was provided for this model, it takes precedent
    if lf.isTbl(optionsRules) then
        
        return optionsRules
    end
    local rules = self:getModelStaticValidationRules() or {}
    --otherwise look for the rules as a static property on the model
    
    return rules
end

-- Gets the validation messages for this model.
-- @return table

function _M:getModelValidationMessages()

    local optionsMessages = self:getOption('messages')
    --if the 'rules' option was provided for this model, it takes precedent
    if lf.isTbl(optionsMessages) then
        
        return optionsMessages
    end
    local rules = self:getModelStaticValidationMessages() or {}
    --otherwise look for the messages as a static property on the model
    
    return rules
end

-- Gets the static rules propery for a model if one exists.
-- @return mixed

function _M:getModelStaticValidationRules()

    local model = self:getDataModel()
    
    return model.rules and lf.isTbl(model.rules) and model.rules or false
end

-- Gets the static messages propery for a model if one exists.
-- @return mixed

function _M:getModelStaticValidationMessages()

    local model = self:getDataModel()
    
    return model.messages and lf.isTbl(model.messages) and model.messages or false
end

-- Gets the relationship inputs.
-- @param \Illuminate\Http\Request request
-- @param table                    fields
-- @return table

function _M.__:getRelationshipInputs(request, fields)

    local inputs = {}
    --run through the edit fields to find the relationships
    for name, field in pairs(fields) do
        if field:getOption('external') then
            inputs[name] = self:formatRelationshipInput(request:get(name, nil), field)
        end
    end
    
    return inputs
end

-- Gets the formatted value of a relationship input.
-- @param string                                 value
-- @param \Frozennode\admin\Fields\Field field
-- @return mixed table | string

function _M.__:formatRelationshipInput(value, field)

    value = str.trim(value)
    if field:getOption('multiple_values') then
        value = value and str.split(value, ',') or {}
    end
    
    return value
end

-- After a model has been saved, this is called to save the relationships.
-- @param \Illuminate\Http\Request            input
-- @param \Illuminate\Database\Eloquent\Model model
-- @param table                               fields

function _M:saveRelationships(input, model, fields)

    --run through the edit fields to see if we need to set relationships
    for name, field in pairs(fields) do
        if field:getOption('external') then
            field:fillModel(model, input:get(name, nil))
        end
    end
end

-- Gets a model's link if one was provided, substituting for field names with this format: (:field_name).
-- @return mixed

function _M:getModelLink()

    local linkCallback = self:getOption('link')
    if linkCallback and lf.isCallable(linkCallback) then
        
        return linkCallback(self:getDataModel())
    else 
        
        return false
    end
end

-- Runs a user-supplied query filter if one is supplied.
-- @param \Illuminate\Database\Query\Builder query

function _M:runQueryFilter(query)

    local filter = self:getOption('query_filter')
    if filter then
        filter(query)
    end
end

-- Fetches the data model for a config given a post input table.
-- @param \Illuminate\Http\Request input
-- @param table                    fields
-- @param int                      id
-- @return \Illuminate\Database\Eloquent\Model

function _M:getFilledDataModel(input, fields, id)

    id = id or 0
    local model = self:getDataModel()
    if id then
        model = model:find(id)
    end
    self:fillModel(model, input, fields)
    
    return model
end

return _M

