
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'configBase',
    _bond_ = 'configInterface'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        type = 'settings',
        defaults = {
        permission = true,
        before_save = nil,
        actions = {},
        rules = {},
        messages = {},
        storage_path = nil
    },
        data = nil,
        rules = {
        title = 'required|string',
        edit_fields = 'required|array|not_empty',
        permission = 'callable',
        before_save = 'callable',
        actions = 'array',
        rules = 'array',
        messages = 'array',
        storage_path = 'directory'
    }
    }
    
    return oo(this, mt)
end

-- The config type.
-- @var string
-- The default configuration options.
-- @var table
-- An table with the settings data.
-- @var table
-- The rules table.
-- @var table
-- Fetches the data model for a config.
-- @return table

function _M:getDataModel()

    return self.data
end

-- Sets the data model for a config.
-- @param table data

function _M:setDataModel(data)

    self.data = data
end

-- Gets the storage directory path.

function _M:getStoragePath()

    local path = self:getOption('storage_path')
    path = path and path or storage_path() .. '/admin_settings/'
    
    return str.rtrim(path, '/') .. '/'
end

-- Fetches the data for this settings config and stores it in the data property.
-- @param table fields

function _M:fetchData(fields)

    --set up the blank data
    local data = {}
    for name, field in pairs(fields) do
        data[name] = nil
    end
    --populate the data from the file
    self:setDataModel(self:populateData(data))
end

-- Populates the data table if it can find the settings file.
-- @param table data
-- @return table

function _M:populateData(data)

    local saveData
    local json
    --attempt to make the storage path if it doesn't already exist
    local path = self:getStoragePath()
    if not is_dir(path) then
        mkdir(path)
    end
    --try to fetch the JSON file
    local file = path .. self:getOption('name') .. '.json'
    if file_exists(file) then
        json = file_get_contents(file)
        saveData = lf.jsde(json)
        --run through the saveData and update the associated fields that we populated from the edit fields
        for field, value in pairs(saveData) do
            if tb.has(data, field) then
                data[field] = value
            end
        end
    end
    
    return data
end

-- Attempts to save a settings page.
-- @param \Illuminate\Http\Request input
-- @param table                    fields
-- @return mixed //string if error, true if success

function _M:save(input, fields)

    local data = {}
    local rules = self:getOption('rules')
    --iterate over the edit fields to only fetch the important items
    for name, field in pairs(fields) do
        if field:getOption('editable') then
            data[name] = input:get(name)
            --make sure the bool field is set correctly
            if field:getOption('type') == 'bool' then
                data[name] = data[name] == 'true' or data[name] == '1' and 1 or 0
            end
        else 
            --unset uneditable fields rules
            unset(rules[name])
        end
    end
    --validate the model
    local validation = self:validateData(data, rules, self:getOption('messages'))
    --if a string was kicked back, it's an error, so return it
    if lf.isStr(validation) then
        
        return validation
    end
    --run the beforeSave function if provided
    local beforeSave = self:runBeforeSave(data)
    --if a string was kicked back, it's an error, so return it
    if lf.isStr(beforeSave) then
        
        return beforeSave
    end
    --Save the JSON data
    self:putToJson(data)
    self:setDataModel(data)
    
    return true
end

-- Runs the before save method with the supplied data.
-- @param table data
-- @param mixed

function _M:runBeforeSave(data)

    local bs
    local beforeSave = self:getOption('before_save')
    if lf.isCallable(beforeSave) then
        bs = beforeSave(data)
        --if a string is returned, assume it's an error and kick it back
        if lf.isStr(bs) then
            
            return bs
        end
    end
    
    return true
end

-- Puts the data contents into the json file.
-- @param table data

function _M:putToJson(data)

    local path = self:getStoragePath()
    --check if the storage path is writable
    if not is_writable(path) then
        lx.throw(\InvalidArgumentException, 'The storage_path option in your ' .. self:getOption('name') .. ' settings config is not writable')
    end
    file_put_contents(path .. self:getOption('name') .. '.json', lf.jsen(data))
end

return _M

