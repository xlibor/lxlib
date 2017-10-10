
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'field'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        defaults = {min_max = true, date_format = 'yy-mm-dd', time_format = 'HH:mm'},
        rules = {date_format = 'string', time_format = 'string'}
    }
    
    return oo(this, mt)
end

-- The specific defaults for subclasses to override.
-- @var table
-- The specific rules for subclasses to override.
-- @var table
-- Filters a query object.
-- @param \Illuminate\Database\Query\Builder query
-- @param table                              selects

function _M:filterQuery(query, selects)

    local time
    local model = self.config:getDataModel()
    local minValue = self:getOption('min_value')
    --try to read the time for the min and max values, and if they check out, set the where
    if minValue then
        time = new('dateTime', minValue)
        if time ~= false then
            query:where(model:getTable() .. '.' .. self:getOption('field_name'), '>=', self:getDateString(time))
        end
    end
    local maxValue = self:getOption('max_value')
    if maxValue then
        time = new('dateTime', maxValue)
        if time ~= false then
            query:where(model:getTable() .. '.' .. self:getOption('field_name'), '<=', self:getDateString(time))
        end
    end
end

-- Fill a model with input data.
-- @param \Illuminate\Database\Eloquent\Model model
-- @param mixed                               input
-- @return table

function _M:fillModel(model, input)

    local time = false
    local field_name = self:getOption('field_name')
    if lf.isEmpty(input) and field_name then
        model.[field_name] = nil
        
        return
    elseif not lf.isEmpty(input) and input ~= '0000-00-00' then
        time = new('dateTime', input)
    end
    --first we validate that it's a date/time
    if time ~= false then
        --fill the model with the correct date/time format
        model.[field_name] = self:getDateString(time)
    end
end

-- Get a date format from a time depending on the type of time field this is.
-- @param int time
-- @return string

function _M:getDateString(time)

    if self:getOption('type') == 'date' then
        
        return time:format('Y-m-d')
    elseif self:getOption('type') == 'datetime' then
        
        return time:format('Y-m-d H:i:s')
    else 
        
        return time:format('H:i:s')
    end
end

return _M

