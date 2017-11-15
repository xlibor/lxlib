
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'field'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        defaults = {editable = false}
    }
    
    return oo(this, mt)
end

-- The specific defaults for subclasses to override.
-- @var table
-- Fill a model with input data.
-- @param \Illuminate\Database\Eloquent\Model model
-- @return table

function _M:fillModel(model, input)

end

-- Filters a query object.
-- @param \Illuminate\Database\Query\Builder query
-- @param table                              selects

function _M:filterQuery(query, selects)

    --run the parent method
    parent.filterQuery(query, selects)
    --if there is no value, return
    if not self:getOption('value') then
        
        return
    end
    query:where(self.config:getDataModel():getTable() .. '.' .. self:getOption('field_name'), '=', self:getOption('value'))
end

return _M

