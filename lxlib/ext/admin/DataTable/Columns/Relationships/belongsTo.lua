
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'relationship'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        relationshipDefaults = {external = false}
    }
    
    return oo(this, mt)
end

-- The relationship-type-specific defaults for the relationship subclasses to override.
-- @var table
-- The class name of a BelongsTo relationship.
-- @var string

const BELONGS_TO = 'Illuminate\\Database\\Eloquent\\Relations\\BelongsTo'
-- Builds the necessary fields on the object.

function _M:build()

    local options = self.suppliedOptions
    self.tablePrefix = self.db:getTablePrefix()
    local nested = self:getNestedRelationships(options['relationship'])
    local relevantName = nested['pieces'][sizeof(nested['pieces']) - 1]
    local relevantModel = nested['models'][sizeof(nested['models']) - 2]
    options['nested'] = nested
    local relationship = relevantModel:[relevantName]()
    local selectTable = options['column_name'] .. '_' .. self.tablePrefix .. relationship:getRelated():getTable()
    --set the relationship object so we can use it later
    self.relationshipObject = relationship
    --replace the (:table) with the generated selectTable
    options['select'] = str.replace(options['select'], '(:table)', selectTable)
    self.suppliedOptions = options
end

-- Converts the relationship key.
-- @param string name //the relationship name
-- @return false|array('models' => table(), 'pieces' => table())

function _M:getNestedRelationships(name)

    local pieces = str.split(name, '.')
    local models = {}
    local num_pieces = sizeof(pieces)
    --iterate over the relationships to see if they're all valid
    for i, rel in pairs(pieces) do
        --if this is the first item, then the model is the config's model
        if i == 0 then
            tapd(models, self.config:getDataModel())
        end
        --if the model method doesn't exist for any of the pieces along the way, exit out
        if not models[i]:__has(rel) or not is_a(models[i]:[rel](), self.BELONGS_TO) then
            lx.throw(\InvalidArgumentException, "The '" .. self:getOption('column_name') .. "' column in your " .. self.config:getOption('name') .. " model configuration needs to be either a belongsTo relationship method name or a sequence of them connected with a '.'")
        end
        --we don't need the model of the last item
        tapd(models, models[i]:[rel]():getRelated())
    end
    
    return {models = models, pieces = pieces}
end

-- Adds selects to a query.
-- @param table selects

function _M:filterQuery(selects)

    local last_alias
    local alias
    local table
    local relationship_model
    local relationship
    local model = self.config:getDataModel()
    local where = ''
    local joins = where
    local columnName = self:getOption('column_name')
    local nested = self:getOption('nested')
    local num_pieces = sizeof(nested['pieces'])
    --if there is more than one nested relationship, we need to join all the tables
    if num_pieces > 1 then
        for i = 1 + 1,num_pieces + 1 do
            model = nested['models'][i]
            relationship = model:[nested['pieces'][i]]()
            relationship_model = relationship:getRelated()
            table = self.tablePrefix .. relationship_model:getTable()
            alias = columnName .. '_' .. table
            last_alias = columnName .. '_' .. self.tablePrefix .. model:getTable()
            joins = joins .. ' LEFT JOIN ' .. table .. ' AS ' .. alias .. ' ON ' .. alias .. '.' .. relationship:getOtherKey() .. ' = ' .. last_alias .. '.' .. relationship:getForeignKey()
        end
    end
    local first_model = nested['models'][0]
    local first_piece = nested['pieces'][0]
    local first_relationship = first_model:[first_piece]()
    local relationship_model = first_relationship:getRelated()
    local from_table = self.tablePrefix .. relationship_model:getTable()
    local field_table = columnName .. '_' .. from_table
    where = self.tablePrefix .. first_model:getTable() .. '.' .. first_relationship:getForeignKey() .. ' = ' .. field_table .. '.' .. first_relationship:getOtherKey()
    tapd(selects, self.db:raw('(SELECT ' .. self:getOption('select') .. ')
										FROM ' .. from_table .. ' AS ' .. field_table .. ' ' .. joins .. '
										WHERE ' .. where .. ') AS ' .. self.db:getQueryGrammar():wrap(columnName))
end

-- Gets all default values.
-- @return table

function _M:getIncludedColumn()

    local model = self.config:getDataModel()
    local nested = self:getOption('nested')
    local fk = nested['models'][0]:[nested['pieces'][0]]():getForeignKey()
    
    return {fk = model:getTable() .. '.' .. fk}
end

return _M

