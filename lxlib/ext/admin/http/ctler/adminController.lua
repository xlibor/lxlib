-- Handles all requests related to managing the data models.


local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'controller'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        request = nil,
        session = nil,
        formRequestErrors = nil,
        layout = 'admin:layouts.default'
    }
    
    return oo(this, mt)
end

-- @var \Illuminate\Http\Request
-- @var \Illuminate\Session\SessionManager
-- @var string
-- @var string
-- @param \Illuminate\Http\Request           request
-- @param \Illuminate\Session\SessionManager session

function _M:ctor(request, session)

    self.request = request
    self.session = session
    self.formRequestErrors = self:resolveDynamicFormRequestErrors(request)
    if self.layout then
        self.layout = view(self.layout)
        self.layout.page = false
        self.layout.dashboard = false
    end
end

-- The main view for any of the data models.
-- @return Response

function _M:index(modelName)

    --set the layout content and title
    self.layout.content = view('admin:index')
    
    return self.layout
end

-- Gets the item edit page / information.
-- @param string modelName
-- @param mixed  itemId

function _M:item(modelName, itemId)

    itemId = itemId or 0
    local response
    local model
    local config = app('itemconfig')
    local fieldFactory = app('admin_field_factory')
    local actionFactory = app('admin_action_factory')
    local columnFactory = app('admin_column_factory')
    local actionPermissions = actionFactory:getActionPermissions()
    local fields = fieldFactory:getEditFields()
    --if it's ajax, we just return the item information as json
    if self.request:ajax() then
        --try to get the object
        model = config:getModel(itemId, fields, columnFactory:getIncludedColumns(fields))
        if model.exists then
            model = config:updateModel(model, fieldFactory, actionFactory)
        end
        response = actionPermissions['view'] and response():json(model) or response():json({success = false, errors = 'You do not have permission to view this item'})
        --set the Vary : Accept header to avoid the browser caching the json response
        
        return response:header('Vary', 'Accept')
    else 
        view = view('admin:index', {itemId = itemId})
        --set the layout content and title
        self.layout.content = view
        
        return self.layout
    end
end

-- POST save method that accepts data via JSON POST and either saves an old item (if id is valid) or creates a new one.
-- @param string modelName
-- @param int    id
-- @return JSON

function _M:save(modelName, id)

    id = id or false
    local config = app('itemconfig')
    local fieldFactory = app('admin_field_factory')
    local actionFactory = app('admin_action_factory')
    if tb.has(config:getOptions(), 'form_request') and self.formRequestErrors ~= nil then
        
        return response():json({success = false, errors = self.formRequestErrors})
    end
    local save = config:save(self.request, fieldFactory:getEditFields(), actionFactory:getActionPermissions(), id)
    if lf.isStr(save) then
        save = str.join(str.split(save, '. '), '<br>')
        
        return response():json({success = false, errors = save})
    else 
        --override the config options so that we can get the latest
        app('admin_config_factory'):updateConfigOptions()
        --grab the latest model data
        columnFactory = app('admin_column_factory')
        fields = fieldFactory:getEditFields()
        model = config:getModel(id, fields, columnFactory:getIncludedColumns(fields))
        if model.exists then
            model = config:updateModel(model, fieldFactory, actionFactory)
        end
        
        return response():json({success = true, data = model:toArray()})
    end
end

-- POST delete method that accepts data via JSON POST and either saves an old.
-- @param string modelName
-- @param int    id
-- @return JSON

function _M:delete(modelName, id)

    local config = app('itemconfig')
    local actionFactory = app('admin_action_factory')
    local baseModel = config:getDataModel()
    local model = baseModel.find(id)
    local errorResponse = {success = false, error = 'There was an error deleting this item. Please reload the page and try again.'}
    --if the model or the id don't exist, send back an error
    local permissions = actionFactory:getActionPermissions()
    if not model.exists or not permissions['delete'] then
        
        return response():json(errorResponse)
    end
    --delete the model
    -- 如果删除成功，或者数据库里面再也找不到了，就算成功
    if model:delete() or not baseModel.find(id) then
        
        return response():json({success = true})
    else 
        
        return response():json(errorResponse)
    end
end

-- Batch delete
-- @param string modelName
-- @param int    id
-- @return JSON

function _M:batchDelete(modelName)

    local config = app('itemconfig')
    local actionFactory = app('admin_action_factory')
    local baseModel = config:getDataModel()
    local errorResponse = {success = false, error = 'There was an error perform batch deletion. Please reload the page and try again.'}
    --if don't have permission, send back request
    local permissions = actionFactory:getActionPermissions()
    if not permissions['delete'] then
        
        return response():json(errorResponse)
    end
    --request ids: 1,3,5
    local ids = str.split(self.request.ids, ',')
    --delete the model
    if baseModel.whereIn('id', ids):delete() then
        
        return response():json({success = true})
    else 
        
        return response():json(errorResponse)
    end
end

-- POST method for handling custom model actions.
-- @param string modelName
-- @return JSON

function _M:customModelAction(modelName)

    local config = app('itemconfig')
    local actionFactory = app('admin_action_factory')
    local actionName = self.request:input('action_name', false)
    local dataTable = app('admin_datatable')
    --get the sort options and filters
    local page = self.request:input('page', 1)
    local sortOptions = self.request:input('sortOptions', {})
    local filters = self.request:input('filters', {})
    --get the prepared query options
    local prepared = dataTable:prepareQuery(app('db'), page, sortOptions, filters)
    --get the action and perform the custom action
    local action = actionFactory:getByName(actionName, true)
    local result = action:perform(prepared['query'])
    --if the result is a string, return that as an error.
    if lf.isStr(result) then
        
        return response():json({success = false, error = result})
    elseif not result then
        messages = action:getOption('messages')
        
        return response():json({success = false, error = messages['error']})
    else 
        response = {success = true}
        --if it's a download response, flash the response to the session and return the download link
        if is_a(result, 'Symfony\\Component\\HttpFoundation\\BinaryFileResponse') then
            file = result:getFile():getRealPath()
            headers = result.headers:all()
            self.session:put('admin_download_response', {file = file, headers = headers})
            response['download'] = route('admin_file_download')
        elseif is_a(result, '\\Illuminate\\Http\\RedirectResponse') then
            response['redirect'] = result:getTargetUrl()
        end
        
        return response():json(response)
    end
end

-- POST method for handling custom model item actions.
-- @param string modelName
-- @param int    id
-- @return JSON

function _M:customModelItemAction(modelName, id)

    local config = app('itemconfig')
    local actionFactory = app('admin_action_factory')
    local model = config:getDataModel()
    model = model.find(id)
    local actionName = self.request:input('action_name', false)
    --get the action and perform the custom action
    local action = actionFactory:getByName(actionName)
    local result = action:perform(model)
    --override the config options so that we can get the latest
    app('admin_config_factory'):updateConfigOptions()
    --if the result is a string, return that as an error.
    if lf.isStr(result) then
        
        return response():json({success = false, error = result})
    elseif not result then
        messages = action:getOption('messages')
        
        return response():json({success = false, error = messages['error']})
    else 
        fieldFactory = app('admin_field_factory')
        columnFactory = app('admin_column_factory')
        fields = fieldFactory:getEditFields()
        model = config:getModel(id, fields, columnFactory:getIncludedColumns(fields))
        if model.exists then
            model = config:updateModel(model, fieldFactory, actionFactory)
        end
        response = {success = true, data = model:toArray()}
        --if it's a download response, flash the response to the session and return the download link
        if is_a(result, 'Symfony\\Component\\HttpFoundation\\BinaryFileResponse') then
            file = result:getFile():getRealPath()
            headers = result.headers:all()
            self.session:put('admin_download_response', {file = file, headers = headers})
            response['download'] = route('admin_file_download')
        elseif is_a(result, '\\Illuminate\\Http\\RedirectResponse') then
            response['redirect'] = result:getTargetUrl()
        end
        
        return response():json(response)
    end
end

-- Shows the dashboard page.
-- @return Response

function _M:dashboard()

    --if the dev has chosen to use a dashboard
    if app:conf('admin.use_dashboard') then
        --set the layout dashboard
        self.layout.dashboard = true
        --set the layout content
        self.layout.content = view(app:conf('admin.dashboard_view'))
        
        return self.layout
    else 
        configFactory = app('admin_config_factory')
        home = app:conf('admin.home_page')
        --first try to find it if it's a model config item
        config = configFactory:make(home)
        if not config then
            lx.throw(\InvalidArgumentException, 'admin: ' .. trans('admin:admin.valid_home_page'))
        elseif config:getType() == 'model' then
            
            return redirect():route('admin_index', {config:getOption('name')})
        elseif config:getType() == 'settings' then
            
            return redirect():route('admin_settings', {config:getOption('name')})
        end
    end
end

-- Gets the database results for the current model.
-- @param string modelName
-- @return table of rows

function _M:results(modelName)

    local dataTable = app('admin_datatable')
    --get the sort options and filters
    local page = self.request:input('page', 1)
    local sortOptions = self.request:input('sortOptions', {})
    local filters = self.request:input('filters', {})
    --return the rows
    
    return response():json(dataTable:getRows(app('db'), filters, page, sortOptions))
end

-- Gets a list of related items given constraints.
-- @param string modelName
-- @return table of objects [{id: string} ... {1: 'name'}, ...]

function _M:updateOptions(modelName)

    local selectedItems
    local fieldName
    local type
    local term
    local constraints
    local fieldFactory = app('admin_field_factory')
    local response = {}
    --iterate over the supplied constrained fields
    for _, field in pairs(self.request:input('fields', {})) do
        --get the constraints, the search term, and the currently-selected items
        constraints = tb.get(field, 'constraints', {})
        term = tb.get(field, 'term', {})
        type = tb.get(field, 'type', false)
        fieldName = tb.get(field, 'field', false)
        selectedItems = tb.get(field, 'selectedItems', false)
        response[fieldName] = fieldFactory:updateRelationshipOptions(fieldName, type, constraints, selectedItems, term)
    end
    
    return response():json(response)
end

-- The GET method that displays a file field's file.
-- @return Image / File

function _M:displayFile()

    --get the stored path of the original
    local path = self.request:input('path')
    local data = File.get(path)
    local file = new('sFile', path)
    local headers = {['Content-Type'] = file:getMimeType(), ['Content-Length'] = file:getSize(), ['Content-Disposition'] = 'attachment; filename="' .. file:getFilename() .. '"'}
    
    return response():make(data, 200, headers)
end

-- The POST method that runs when a user uploads a file on a file field.
-- @param string modelName
-- @param string fieldName
-- @return JSON

function _M:fileUpload(modelName, fieldName)

    local fieldFactory = app('admin_field_factory')
    --get the model and the field object
    local field = fieldFactory:findField(fieldName)
    
    return response():JSON(field:doUpload())
end

-- The GET method that runs when a user needs to download a file.
-- @return JSON

function _M:fileDownload()

    local filename
    local response = self.session:get('admin_download_response')
    if response then
        self.session:forget('admin_download_response')
        filename = str.substr(response['headers']['content-disposition'][0], 22, -1)
        
        return response():download(response['file'], filename, response['headers'])
    else 
        
        return redirect():back()
    end
end

-- The POST method for setting a user's rows per page.
-- @param string modelName
-- @return JSON

function _M:rowsPerPage(modelName)

    local dataTable = app('admin_datatable')
    --get the inputted rows and the model rows
    local rows = tonumber(self.request:input('rows', 20))
    dataTable:setRowsPerPage(app('session.store'), 0, rows)
    
    return response():JSON({success = true})
end

-- The pages view.
-- @return Response

function _M:page(page)

    --set the page
    self.layout.page = page
    --set the layout content and title
    self.layout.content = view(page)
    
    return self.layout
end

-- The main view for any of the settings pages.
-- @param string settingsName
-- @return Response

function _M:settings(settingsName)

    --set the layout content and title
    self.layout.content = view('admin:settings')
    
    return self.layout
end

-- POST save settings method that accepts data via JSON POST and either saves an old item (if id is valid) or creates a new one.
-- @return JSON

function _M:settingsSave()

    local config = app('itemconfig')
    local save = config:save(self.request, app('admin_field_factory'):getEditFields())
    if lf.isStr(save) then
        
        return response():json({success = false, errors = save})
    else 
        --override the config options so that we can get the latest
        app('admin_config_factory'):updateConfigOptions()
        
        return response():json({success = true, data = config:getDataModel(), actions = app('admin_action_factory'):getActionsOptions()})
    end
end

-- POST method for handling custom actions on the settings page.
-- @param string settingsName
-- @return JSON

function _M:settingsCustomAction(settingsName)

    local config = app('itemconfig')
    local actionFactory = app('admin_action_factory')
    local actionName = self.request:input('action_name', false)
    --get the action and perform the custom action
    local action = actionFactory:getByName(actionName)
    local data = config:getDataModel()
    local result = action:perform(data)
    --override the config options so that we can get the latest
    app('admin_config_factory'):updateConfigOptions()
    --if the result is a string, return that as an error.
    if lf.isStr(result) then
        
        return response():json({success = false, error = result})
    elseif not result then
        messages = action:getOption('messages')
        
        return response():json({success = false, error = messages['error']})
    else 
        response = {success = true, actions = actionFactory:getActionsOptions(true)}
        --if it's a download response, flash the response to the session and return the download link
        if is_a(result, 'Symfony\\Component\\HttpFoundation\\BinaryFileResponse') then
            file = result:getFile():getRealPath()
            headers = result.headers:all()
            self.session:put('admin_download_response', {file = file, headers = headers})
            response['download'] = route('admin_file_download')
        elseif is_a(result, '\\Illuminate\\Http\\RedirectResponse') then
            response['redirect'] = result:getTargetUrl()
        end
        
        return response():json(response)
    end
end

-- POST method for switching a user's locale.
-- @param string locale
-- @return JSON

function _M:switchLocale(locale)

    if tb.inList(app:conf('admin.locales'), locale) then
        self.session:put('admin_locale', locale)
    end
    
    return redirect():back()
end

-- POST method to capture any form request errors.
-- @param \Illuminate\Http\Request request

function _M.__:resolveDynamicFormRequestErrors(request)

    try(function()
        config = app('itemconfig')
        fieldFactory = app('admin_field_factory')
    end)
    :catch(function(\ReflectionException e) 
        
        return
    end)
    :run()
    if tb.has(config:getOptions(), 'form_request') then
        try(function()
            model = config:getFilledDataModel(request, fieldFactory:getEditFields(), request.id)
            request:merge(model:toArray())
            formRequestClass = config:getOption('form_request')
            app(formRequestClass)
        end)
        :catch(function(HttpResponseException e) 
            --Parses the exceptions thrown by Illuminate\Foundation\Http\FormRequest
            errorMessages = e:getResponse():getContent()
            errorsArray = lf.jsde(errorMessages)
            if not errorsArray and lf.isStr(errorMessages) then
                
                return errorMessages
            end
            if errorsArray then
                
                return str.join(array_dot(errorsArray), '.')
            end
        end)
        :run()
    end
    
    return
end

return _M

