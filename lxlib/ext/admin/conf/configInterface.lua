local __ = {
    _cls_ = ''
}
-- Fetches the data model for a config.
-- @return mixed

function __:getDataModel() end

-- Sets the data model for a config.
-- @param  model

function __:setDataModel(model) end

-- Gets a config option from the supplied table.
-- @param string key
-- @return mixed

function __:getOption(key) end

-- Saves the data.
-- @param \Illuminate\Http\Request input
-- @param table                    fields

function __:save(input, fields) end

-- Gets the config type.

function __:getType() end

return __

