
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'relationship'
}

local app, lf, tb, str = lx.kit()

-- Adds selects to a query.
-- @param table selects

function _M:filterQuery(selects)

    local model = self.config:getDataModel()
    local where = ''
    local joins = where
    local columnName = self:getOption('column_name')
    local relationship = model:[self:getOption('relationship')]()
    local from_table = self.tablePrefix .. relationship:getRelated():getTable()
    local field_table = columnName .. '_' .. from_table
    --grab the existing where clauses that the user may have set on the relationship
    local relationshipWheres = self:getRelationshipWheres(relationship, field_table)
    where = self.tablePrefix .. relationship:getQualifiedParentKeyName() .. ' = ' .. field_table .. '.' .. relationship:getPlainForeignKey() .. (relationshipWheres and ' AND ' .. relationshipWheres or '')
    tapd(selects, self.db:raw('(SELECT ' .. self:getOption('select') .. ')
										FROM ' .. from_table .. ' AS ' .. field_table .. ' ' .. joins .. '
										WHERE ' .. where .. ') AS ' .. self.db:getQueryGrammar():wrap(columnName))
end

return _M

