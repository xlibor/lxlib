
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'relationship'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        relationshipDefaults = {belongs_to_many = true}
    }
    
    return oo(this, mt)
end

-- The relationship-type-specific defaults for the relationship subclasses to override.
-- @var table
-- Adds selects to a query.
-- @param table selects

function _M:filterQuery(selects)

    local model = self.config:getDataModel()
    local where = ''
    local joins = where
    local columnName = self:getOption('column_name')
    local relationship = model:[self:getOption('relationship')]()
    local from_table = self.tablePrefix .. model:getTable()
    local field_table = columnName .. '_' .. from_table
    local other_table = self.tablePrefix .. relationship:getRelated():getTable()
    local other_alias = columnName .. '_' .. other_table
    local other_model = relationship:getRelated()
    local other_key = other_model:getKeyName()
    local int_table = self.tablePrefix .. relationship:getTable()
    local int_alias = columnName .. '_' .. int_table
    local column1 = str.split(relationship:getForeignKey(), '.')
    column1 = column1[1]
    local column2 = str.split(relationship:getOtherKey(), '.')
    column2 = column2[1]
    joins = joins .. ' LEFT JOIN ' .. int_table .. ' AS ' .. int_alias .. ' ON ' .. int_alias .. '.' .. column1 .. ' = ' .. field_table .. '.' .. model:getKeyName() .. ' LEFT JOIN ' .. other_table .. ' AS ' .. other_alias .. ' ON ' .. other_alias .. '.' .. other_key .. ' = ' .. int_alias .. '.' .. column2
    --grab the existing where clauses that the user may have set on the relationship
    local relationshipWheres = self:getRelationshipWheres(relationship, other_alias, int_alias, int_table)
    where = self.tablePrefix .. model:getTable() .. '.' .. model:getKeyName() .. ' = ' .. int_alias .. '.' .. column1 .. (relationshipWheres and ' AND ' .. relationshipWheres or '')
    tapd(selects, self.db:raw('(SELECT ' .. self:getOption('select') .. ')
										FROM ' .. from_table .. ' AS ' .. field_table .. ' ' .. joins .. '
										WHERE ' .. where .. ') AS ' .. self.db:getQueryGrammar():wrap(columnName))
end

-- Gets all default values.
-- @return table

function _M:getIncludedColumn()

    local model = self.config:getDataModel()
    local fk = model:[self:getOption('relationship')]():getRelated():getKeyName()
    
    return {fk = model:getTable() .. '.' .. fk}
end

return _M

