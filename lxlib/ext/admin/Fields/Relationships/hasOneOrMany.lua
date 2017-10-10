
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'relationship'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        relationshipDefaults = {editable = false}
    }
    
    return oo(this, mt)
end

-- The relationship-type-specific defaults for the relationship subclasses to override.
-- @var table
-- Builds a few basic options.

function _M:build()

    parent.build()
    local options = self.suppliedOptions
    local model = self.config:getDataModel()
    local relationship = model:[options['field_name']]()
    local related_model = relationship:getRelated()
    options['table'] = related_model:getTable()
    options['column'] = relationship:getPlainForeignKey()
    self.suppliedOptions = options
end

-- Filters a query object with this item's data (currently empty because there's no easy way to represent this).
-- @param \Illuminate\Database\Query\Builder query
-- @param table                              selects

function _M:filterQuery(query, selects)

end

-- For the moment this is an empty function until I can figure out a way to display HasOne and HasMany relationships on this model.
-- @param \Illuminate\Database\Eloquent\Model model
-- @return table

function _M:fillModel(model, input)

end

-- Constrains a query by a given set of constraints.
-- @param \Illuminate\Database\Eloquent\Builder query
-- @param \Illuminate\Database\Eloquent\Model   relatedModel
-- @param string                                constraint

function _M:constrainQuery(query, relatedModel, constraint)

    query:where(self:getOption('column'), '=', constraint)
end

return _M

