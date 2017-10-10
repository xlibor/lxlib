
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'field'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        rules = {options = 'required|array|not_empty'}
    }
    
    return oo(this, mt)
end

-- The options used for the enum field.
-- @var table
-- Builds a few basic options.

function _M:build()

    parent.build()
    local options = self.suppliedOptions
    local dataOptions = options['options']
    options['options'] = {}
    --iterate over the options to create the options assoc table
    for val, text in pairs(dataOptions) do
        tapd(options['options'], {id = lf.isNum(val) and text or val, text = text})
    end
    self.suppliedOptions = options
end

-- Fill a model with input data.
-- @param \Illuminate\Database\Eloquent\model model
-- @param mixed                               input

function _M:fillModel(model, input)

    model.[self:getOption('field_name')] = input
end

-- Sets the filter options for this item.
-- @param table filter

function _M:setFilter(filter)

    parent.setFilter(filter)
    self.userOptions['value'] = self:getOption('value') == '' and nil or self:getOption('value')
end

-- Filters a query object.
-- @param \Illuminate\Database\Query\Builder query
-- @param table                              selects

function _M:filterQuery(query, selects)

    --run the parent method
    parent.filterQuery(query, selects)
    --if there is no value, return
    if self:getFilterValue(self:getOption('value')) == false then
        
        return
    end
    query:where(self.config:getDataModel():getTable() .. '.' .. self:getOption('field_name'), '=', self:getOption('value'))
end

return _M

