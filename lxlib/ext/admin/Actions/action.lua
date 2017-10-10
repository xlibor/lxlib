
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        validator = nil,
        config = nil,
        suppliedOptions = {},
        options = {},
        defaults = {
        title = 'Custom Action',
        has_permission = true,
        confirmation = false,
        messages = {active = 'Just a moment...', success = 'Success!', error = 'There was an error performing this action'}
    },
        rules = {
        title = 'string_or_callable',
        confirmation = 'string_or_callable',
        messages = 'array|array_with_all_or_none:active,success,error',
        action = 'required|callable'
    }
    }
    
    return oo(this, mt)
end

-- The validator instance.
-- @var \Frozennode\Administrator\Validator
-- The config instance.
-- @var \Frozennode\Administrator\Config\ConfigInterface
-- The user supplied options table.
-- @var table
-- The options table.
-- @var table
-- The default configuration options.
-- @var table
-- The base rules that all fields need to pass.
-- @var table
-- Create a new action Factory instance.
-- @param \Frozennode\Administrator\Validator              validator
-- @param \Frozennode\Administrator\Config\ConfigInterface config
-- @param table                                            options

function _M:ctor(validator, config, options)

    self.config = config
    self.validator = validator
    self.suppliedOptions = options
end

-- Validates the supplied options.

function _M:validateOptions()

    --override the config
    self.validator:override(self.suppliedOptions, self.rules)
    --if the validator failed, throw an exception
    if self.validator:fails() then
        lx.throw(\InvalidArgumentException, "There are problems with your '" .. self.suppliedOptions['action_name'] .. "' action in the " .. self.config:getOption('name') .. ' model: ' .. str.join(self.validator:messages():all(), '. '))
    end
end

-- Builds the necessary fields on the object.

function _M:build()

    local options = self.suppliedOptions
    --build the string or func values for title and confirmation
    self:buildStringOrCallable(options, {'confirmation', 'title'})
    --build the string or func values for the messages
    local messages = self.validator:arrayGet(options, 'messages', {})
    self:buildStringOrCallable(messages, {'active', 'success', 'error'})
    options['messages'] = messages
    --override the supplied options
    self.suppliedOptions = options
end

-- Sets up the values of all the options that can be either strings or closures.
-- @param table options //the passed-by-reference table on which to do the transformation
-- @param table keys    //the keys to check

function _M:buildStringOrCallable(options, keys)

    local suppliedValue
    local model = self.config:getDataModel()
    --iterate over the keys
    for _, key in pairs(keys) do
        --check if the key's value was supplied
        suppliedValue = self.validator:arrayGet(options, key)
        --if it's a string, simply set it
        if lf.isStr(suppliedValue) then
            options[key] = suppliedValue
        elseif lf.isCallable(suppliedValue) then
            options[key] = suppliedValue(model)
        end
    end
end

-- Performs the callback of the action and returns its result.
-- @param mixed data
-- @return table

function _M:perform(data)

    local action = self:getOption('action')
    
    return action(data)
end

-- Gets all user options.
-- @param bool override
-- @return table

function _M:getOptions(override)

    override = override or false
    --if override is true, unset the current options
    self.options = override and {} or self.options
    --make sure the supplied options have been merged with the defaults
    if lf.isEmpty(self.options) then
        --validate the options and build them
        self:validateOptions()
        self:build()
        self.options = tb.merge(self.defaults, self.suppliedOptions)
    end
    
    return self.options
end

-- Gets a field's option.
-- @param string key
-- @return mixed

function _M:getOption(key)

    local options = self:getOptions()
    if not tb.has(options, key) then
        lx.throw(\InvalidArgumentException, "An invalid option was searched for in the '" .. options['action_name'] .. "' action")
    end
    
    return options[key]
end

return _M

