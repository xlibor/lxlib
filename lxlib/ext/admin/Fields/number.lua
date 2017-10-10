
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'field'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        defaults = {
        min_max = true,
        symbol = '',
        decimals = 0,
        thousands_separator = ',',
        decimal_separator = '.'
    },
        rules = {
        symbol = 'string',
        decimals = 'integer',
        thousands_separator = 'string',
        decimal_separator = 'string'
    }
    }
    
    return oo(this, mt)
end

-- The specific defaults for subclasses to override.
-- @var table
-- The specific rules for subclasses to override.
-- @var table
-- Sets the filter options for this item.
-- @param table filter

function _M:setFilter(filter)

    parent.setFilter(filter)
    local minValue = self:getOption('min_value')
    local maxValue = self:getOption('max_value')
    self.userOptions['min_value'] = minValue and str.replace(minValue, ',', '') or minValue
    self.userOptions['max_value'] = maxValue and str.replace(maxValue, ',', '') or maxValue
end

-- Fill a model with input data.
-- @param \Illuminate\Database\Eloquent\Model model
-- @param mixed                               input
-- @return table

function _M:fillModel(model, input)

    model.[self:getOption('field_name')] = not input or input == '' and nil or self:parseNumber(input)
end

-- Parses a user-supplied number into the required SQL format with no commas for thousands and a . for decimals.
-- @param string number
-- @return string

function _M:parseNumber(number)

    return str.replace(str.replace(number, self:getOption('thousands_separator'), ''), self:getOption('decimal_separator'), '.')
end

return _M

