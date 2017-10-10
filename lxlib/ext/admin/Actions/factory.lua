
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        validator = nil,
        config = nil,
        actions = {},
        actionsOptions = {},
        actionPermissions = {},
        globalActions = {},
        globalActionsOptions = {},
        actionPermissionsDefaults = {
        create = true,
        delete = true,
        update = true,
        view = true
    }
    }
    
    return oo(this, mt)
end

-- The validator instance.
-- @var \Frozennode\Administrator\Validator
-- The config instance.
-- @var \Frozennode\Administrator\Config\ConfigInterface
-- The actions table.
-- @var table
-- The table of actions options.
-- @var table
-- The action permissions table.
-- @var table
-- The global actions table.
-- @var table
-- The table of global actions options.
-- @var table
-- The action permissions defaults.
-- @var table
-- Create a new action Factory instance.
-- @param \Frozennode\Administrator\Validator              validator
-- @param \Frozennode\Administrator\Config\ConfigInterface config

function _M:ctor(validator, config)

    self.config = config
    self.validator = validator
end

-- Takes the model and an info table of options for the specific action.
-- @param string name    //the key name for this action
-- @param table  options
-- @return \Frozennode\Administrator\Actions\Action

function _M:make(name, options)

    --check the permission on this item
    options = self:parseDefaults(name, options)
    --now we can instantiate the object
    
    return self:getActionObject(options)
end

-- Sets up the default values for the options table.
-- @param string name    //the key name for this action
-- @param table  options
-- @return table

function _M:parseDefaults(name, options)

    local model = self.config:getDataModel()
    --if the name is not a string or the options is not an table at this point, throw an error because we can't do anything with it
    if not lf.isStr(name) or not lf.isTbl(options) then
        lx.throw(\InvalidArgumentException, 'A custom action in your  ' .. self.config:getOption('action_name') .. ' configuration file is invalid')
    end
    --set the action name
    options['action_name'] = name
    --set the permission
    local permission = self.validator:arrayGet(options, 'permission', false)
    options['has_permission'] = lf.isCallable(permission) and permission(model) or true
    --check if the messages table exists
    options['messages'] = self.validator:arrayGet(options, 'messages', {})
    options['messages'] = lf.isTbl(options['messages']) and options['messages'] or {}
    
    return options
end

-- Gets an Action object.
-- @param table options
-- @return \Frozennode\Administrator\Actions\Action

function _M:getActionObject(options)

    return new('action', self.validator, self.config, options)
end

-- Gets an action by name.
-- @param string name
-- @param bool   global //if true, search the global actions
-- @return mixed

function _M:getByName(name, global)

    global = global or false
    local actions = global and self:getGlobalActions() or self:getActions()
    --loop over the actions to find our culprit
    for _, action in pairs(actions) do
        if action:getOption('action_name') == name then
            
            return action
        end
    end
    
    return false
end

-- Gets all actions.
-- @param bool override
-- @return table of Action objects

function _M:getActions(override)

    override = override or false
    --make sure we only run this once and then return the cached version
    if not sizeof(self.actions) or override then
        self.actions = {}
        --loop over the actions to build the list
        for name, options in pairs(self.config:getOption('actions')) do
            tapd(self.actions, self:make(name, options))
        end
    end
    
    return self.actions
end

-- Gets all actions as tables of options.
-- @param bool override
-- @return table of Action options

function _M:getActionsOptions(override)

    override = override or false
    --make sure we only run this once and then return the cached version
    if not sizeof(self.actionsOptions) or override then
        self.actionsOptions = {}
        --loop over the actions to build the list
        for name, action in pairs(self:getActions(override)) do
            tapd(self.actionsOptions, action:getOptions(true))
        end
    end
    
    return self.actionsOptions
end

-- Gets all global actions.
-- @param bool override
-- @return table of Action objects

function _M:getGlobalActions(override)

    override = override or false
    --make sure we only run this once and then return the cached version
    if not sizeof(self.globalActions) or override then
        self.globalActions = {}
        --loop over the actions to build the list
        for name, options in pairs(self.config:getOption('global_actions')) do
            tapd(self.globalActions, self:make(name, options))
        end
    end
    
    return self.globalActions
end

-- Gets all actions as tables of options.
-- @param bool override
-- @return table of Action options

function _M:getGlobalActionsOptions(override)

    override = override or false
    --make sure we only run this once and then return the cached version
    if not sizeof(self.globalActionsOptions) or override then
        self.globalActionsOptions = {}
        --loop over the global actions to build the list
        for name, action in pairs(self:getGlobalActions(override)) do
            tapd(self.globalActionsOptions, action:getOptions())
        end
    end
    
    return self.globalActionsOptions
end

-- Gets all action permissions.
-- @param bool override
-- @return table of Action objects

function _M:getActionPermissions(override)

    override = override or false
    local permissions
    local defaults
    local options
    local model
    --make sure we only run this once and then return the cached version
    if not sizeof(self.actionPermissions) or override then
        self.actionPermissions = {}
        model = self.config:getDataModel()
        options = self.config:getOption('action_permissions')
        defaults = self.actionPermissionsDefaults
        --merge the user-supplied action permissions into the defaults
        permissions = tb.merge(defaults, options)
        --loop over the actions to build the list
        for action, callback in pairs(permissions) do
            if lf.isCallable(callback) then
                self.actionPermissions[action] = callback(model)
            else 
                self.actionPermissions[action] = callback
            end
        end
    end
    
    return self.actionPermissions
end

return _M

