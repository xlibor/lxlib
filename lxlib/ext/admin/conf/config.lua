
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        validator = nil,
        customValidator = nil,
        suppliedOptions = {},
        options = nil,
        defaults = {},
        rules = {}
    }
    
    return oo(this, mt)
end

-- The validator instance.
-- @var \Frozennode\admin\Validator
-- The site's normal validator instance.
-- @var \Illuminate\Validation\Validator
-- The user supplied options table.
-- @var table
-- The original configuration options that were supplied.
-- @var table
-- The defaults property.
-- @var table
-- The rules property.
-- @var table
-- Create a new model Config instance.
-- @param \Frozennode\admin\Validator validator
-- @param \Illuminate\Validation\Validator    custom_validator
-- @param table                               options

function _M:ctor(validator, custom_validator, options)

    self.validator = validator
    self.customValidator = custom_validator
    self.suppliedOptions = options
end

-- Validates the supplied options.

function _M:validateOptions()

    --override the config
    self.validator:override(self.suppliedOptions, self.rules)
    --if the validator failed, throw an exception
    if self.validator:fails() then
        lx.throw(\InvalidArgumentException, 'There are problems with your ' .. self.suppliedOptions['name'] .. ' config: ' .. str.join(self.validator:messages():all(), '. '))
    end
end

-- Builds the necessary fields on the object.

function _M:build()

    local options = self.suppliedOptions
    --check the permission
    options['permission'] = options['permission'] and options['permission']() or true
    self.suppliedOptions = options
end

-- Config type getter.
-- @return string

function _M:getType()

    return self.type
end

-- Gets all user options.
-- @return table

function _M:getOptions()

    --make sure the supplied options have been merged with the defaults
    if lf.isEmpty(self.options) then
        --validate the options and build them
        self:validateOptions()
        self:build()
        self.options = tb.merge(self.defaults, self.suppliedOptions)
    end
    
    return self.options
end

-- Gets a config option.
-- @param string key
-- @param null   default
-- @return mixed

function _M:getOption(key, default)

    local options = self:getOptions()
    if not tb.has(options, key) then
        if default ~= nil then
            
            return default
        end
        lx.throw(\InvalidArgumentException, "An invalid option was searched for in the '" .. options['name'] .. "' config")
    end
    
    return options[key]
end

-- Sets the user options.
-- @param table options
-- @return table

function _M:setOptions(options)

    --unset the current options
    self.options = {}
    --override the supplied options
    self.suppliedOptions = options
end

-- Validates the supplied data against the options rules.
-- @param table data
-- @param table rules
-- @param table messages
-- @param mixed

function _M:validateData(data, rules, messages)

    if rules then
        self.customValidator:setData(data)
        self.customValidator:setRules(rules)
        self.customValidator:setCustomMessages(messages)
        --if the validator fails, kick back the errors
        if self.customValidator:fails() then
            
            return str.join(self.customValidator:messages():all(), '. ')
        end
    end
    
    return true
end

return _M

