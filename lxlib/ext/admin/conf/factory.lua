
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        validator = nil,
        customValidator = nil,
        config = nil,
        options = nil,
        name = nil,
        type = nil,
        settingsPrefix = 'settings.',
        pagePrefix = 'page.',
        rules = {
        uri = 'required|string',
        title = 'required|string',
        model_config_path = 'required|string|directory',
        settings_config_path = 'required|string|directory',
        menu = 'required|array|not_empty',
        permission = 'required|callable',
        use_dashboard = 'required',
        dashboard_view = 'string',
        home_page = 'string',
        login_path = 'required|string',
        login_redirect_key = 'required|string'
    }
    }
    
    return oo(this, mt)
end

-- The validator instance.
-- @var \Frozennode\Administrator\Validator
-- The site's normal validator instance.
-- @var \Illuminate\Validation\Validator
-- The config instance.
-- @var \Frozennode\Administrator\Config\ConfigInterface
-- The main options table.
-- @var table
-- The config name.
-- @var string
-- The config type (settings or model).
-- @var string
-- The settings page menu prefix.
-- @var string
-- The custom view page menu prefix.
-- @var string
-- The rules table.
-- @var table
-- Create a new config Factory instance.
-- @param \Frozennode\Administrator\Validator validator
-- @param \Illuminate\Validation\Validator    custom_validator
-- @param table                               options

function _M:ctor(validator, custom_validator, options)

    --set the config, and then validate it
    self.options = options
    self.validator = validator
    self.customValidator = custom_validator
    validator:override(self.options, self.rules)
    --if the validator failed, throw an exception
    if validator:fails() then
        lx.throw(\InvalidArgumentException, 'There are problems with your administrator.php config: ' .. str.join(validator:messages():all(), '. '))
    end
end

-- Makes a config instance given an input string.
-- @param string name
-- @param string primary //if true, this is the primary itemconfig object and we want to store the instance
-- @return mixed

function _M:make(name, primary)

    primary = primary or false
    --set the name so we can rebuild the config later if necessary
    self.name = primary and name or self.name
    --search the config menu for our item
    local options = self:searchMenu(name)
    --return the config object if the file/array was found, or false if it wasn't
    local config = options and self:getItemConfigObject(options) or (self.type == 'page' and true or false)
    --set the primary config
    self.config = primary and config or self.config
    --return the config object (or false if it fails to build)
    
    return config
end

-- Updates the current item config's options.

function _M:updateConfigOptions()

    --search the config menu for our item
    local options = self:searchMenu(self.name)
    --override the config's options
    self:getConfig():setOptions(options)
end

-- Gets the current config item.
-- @return \Frozennode\Administrator\Config\ConfigInterface

function _M:getConfig()

    return self.config
end

-- Determines whether a string is a model or settings config.
-- @param string name
-- @return string

function _M:parseType(name)

    --if the name is prefixed with the settings prefix
    if str.strpos(name, self.settingsPrefix) == 0 then
        
        return self.type = 'settings'
    elseif str.strpos(name, self.pagePrefix) == 0 then
        
        return self.type = 'page'
    else 
        
        return self.type = 'model'
    end
end

-- Recursively searches the menu table for the desired settings config name.
-- @param string name
-- @param table  menu
-- @return false|array //If found, an table of (unvalidated) config options will returned

function _M:searchMenu(name, menu)

    menu = menu or false
    --parse the type based on the config name if this is the top-level item
    if menu == false then
        self:parseType(name)
    end
    local config = false
    menu = menu and menu or self.options['menu']
    --iterate over all the items in the menu table
    for key, item in pairs(menu) do
        --if the item is a string, try to find the config file
        if lf.isStr(item) and item == name then
            config = self:fetchConfigFile(name)
        elseif lf.isTbl(item) then
            config = self:searchMenu(name, item)
        end
        --if the config var was set, break the loop
        if lf.isTbl(config) then
            break
        end
    end
    
    return config
end

-- Gets the prefix for the currently-searched item.

function _M:getSettingsPrefix()

    return self.settingsPrefix
end

-- Gets the prefix for the currently-searched item.

function _M:getPagePrefix()

    return self.pagePrefix
end

-- Gets the prefix for the currently-searched item.

function _M:getPrefix()

    if self.type == 'settings' then
        
        return self.settingsPrefix
    elseif self.type == 'page' then
        
        return self.pagePrefix
    end
    
    return ''
end

-- Gets the type for the currently-searched item.

function _M:getType()

    return self.type
end

-- Gets the config directory path for the currently-searched item.

function _M:getPath()

    local path = self.type == 'settings' and self.options['settings_config_path'] or self.options['model_config_path']
    
    return str.rtrim(path, '/') .. '/'
end

-- Gets the config rules.

function _M:getRules()

    return self.rules
end

-- Gets an instance of the config.
-- @param table options
-- @return \Frozennode\Administrator\Config\ConfigInterface

function _M:getItemConfigObject(options)

    if self.type == 'settings' then
        
        return new('settingsConfig', self.validator, self.customValidator, options)
    else 
        
        return new('modelConfig', self.validator, self.customValidator, options)
    end
end

-- Fetches a config file given a path.
-- @param string name
-- @return mixed

function _M:fetchConfigFile(name)

    local options
    name = str.replace(name, self:getPrefix(), '')
    local path = self:getPath() .. name .. '.php'
    --check that this is a legitimate file
    if is_file(path) then
        --set the options var
        options = (require path)
        --add the name in
        options['name'] = name
        
        return options
    end
    
    return false
end

return _M

