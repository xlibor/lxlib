
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'field'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        value = false
    }
    
    return oo(this, mt)
end

-- The value (used in filter).
-- @var bool
-- Builds a few basic options.

function _M:build()

    parent.build()
    local value = self.validator:arrayGet(self.suppliedOptions, 'value', true)
    --we need to set the value to 'false' when it is falsey so it plays nicely with select2
    if not value and value ~= '' then
        self.suppliedOptions['value'] = 'false'
    end
end

-- Fill a model with input data.
-- @param \Illuminate\Database\Eloquent\Model model
-- @param mixed                               input

function _M:fillModel(model, input)

    model.[self:getOption('field_name')] = input == 'true' or input == '1' or input == true and 1 or 0
end

-- Sets the filter options for this item.
-- @param table filter

function _M:setFilter(filter)

    parent.setFilter(filter)
    self.userOptions['value'] = self.validator:arrayGet(filter, 'value', '')
    --if it isn't null, we have to check the 'true'/'false' string
    if self.userOptions['value'] ~= '' then
        self.userOptions['value'] = self.userOptions['value'] == 'false' or not self.userOptions['value'] and 0 or 1
    end
end

-- Filters a query object.
-- @param \Illuminate\Database\Query\Builder query
-- @param table                              selects

function _M:filterQuery(query, selects)

    --if the field isn't empty
    if self:getOption('value') ~= '' then
        query:where(self.config:getDataModel():getTable() .. '.' .. self:getOption('field_name'), '=', self:getOption('value'))
    end
end

return _M

