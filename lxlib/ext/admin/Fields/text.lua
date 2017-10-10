
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'field'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        defaults = {limit = 0, height = 100},
        rules = {limit = 'integer|min:0', height = 'integer|min:0'}
    }
    
    return oo(this, mt)
end

-- The specific defaults for subclasses to override.
-- @var table
-- The specific rules for subclasses to override.
-- @var table
-- Filters a query object given.
-- @param \Illuminate\Database\Query\Builder query
-- @param table                              selects

function _M:filterQuery(query, selects)

    --run the parent method
    parent.filterQuery(query, selects)
    --if there is no value, return
    if self:getFilterValue(self:getOption('value')) == false then
        
        return
    end
    query:where(self.config:getDataModel():getTable() .. '.' .. self:getOption('field_name'), 'LIKE', '%' .. self:getOption('value') .. '%')
end

return _M

