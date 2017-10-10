
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        validator = nil,
        config = nil,
        db = nil,
        columns = {},
        columnOptions = {},
        includedColumns = {},
        relatedColumns = {},
        computedColumns = {}
    }
    
    return oo(this, mt)
end

-- The validator instance.
-- @var \Frozennode\Administrator\Validator
-- The config instance.
-- @var \Frozennode\Administrator\Config\ConfigInterface
-- The config instance.
-- @var \Illuminate\Database\DatabaseManager
-- The column objects.
-- @var table
-- The column options tables.
-- @var table
-- The included column (used for pulling a certain range of selects from the DB).
-- @var table
-- The relationship columns.
-- @var table
-- The computed columns (either an accessor or a select was supplied).
-- @var table
-- The class name of a BelongsTo relationship.
-- @var string

const BELONGS_TO = 'Illuminate\\Database\\Eloquent\\Relations\\BelongsTo'
-- The class name of a BelongsToMany relationship.
-- @var string

const BELONGS_TO_MANY = 'Illuminate\\Database\\Eloquent\\Relations\\BelongsToMany'
-- The class name of a HasMany relationship.
-- @var string

const HAS_MANY = 'Illuminate\\Database\\Eloquent\\Relations\\HasMany'
-- The class name of a HasOne relationship.
-- @var string

const HAS_ONE = 'Illuminate\\Database\\Eloquent\\Relations\\HasOne'
-- Create a new action Factory instance.
-- @param \Frozennode\Administrator\Validator              validator
-- @param \Frozennode\Administrator\Config\ConfigInterface config
-- @param \Illuminate\Database\DatabaseManager             db

function _M:ctor(validator, config, db)

    --set the config, and then validate it
    self.config = config
    self.validator = validator
    self.db = db
end

-- Fetches a Column instance from the supplied options.
-- @param table options
-- @return \Frozennode\Administrator\DataTable\Columns\Column

function _M:make(options)

    return self:getColumnObject(options)
end

-- Creates the Column instance.
-- @param table options
-- @return \Frozennode\Administrator\DataTable\Columns\Column

function _M:getColumnObject(options)

    local class = self:getColumnClassName(options)
    
    return new('class', self.validator, self.config, self.db, options)
end

-- Gets the column class name depending on whether or not it's a relationship and what type of relationship it is.
-- @param table options
-- @return string

function _M:getColumnClassName(options)

    local relationship
    local model = self.config:getDataModel()
    local namespace = __NAMESPACE__ .. '\\'
    local method = self.validator:arrayGet(options, 'relationship')
    --if the relationship is set
    if method then
        if model:__has(method) then
            relationship = model:[method]()
            if is_a(relationship, self.BELONGS_TO_MANY) then
                
                return namespace .. 'Relationships\\BelongsToMany'
            elseif is_a(relationship, self.HAS_ONE) or is_a(relationship, self.HAS_MANY) then
                
                return namespace .. 'Relationships\\HasOneOrMany'
            end
        end
        --assume it's a nested relationship
        
        return namespace .. 'Relationships\\BelongsTo'
    end
    
    return namespace .. 'Column'
end

-- Parses an options table and a string name and returns an options table with the column_name option set.
-- @param mixed name
-- @param mixed options
-- @return table

function _M:parseOptions(name, options)

    if lf.isStr(options) then
        name = options
        options = {}
    end
    --if the name is not a string or the options is not an table at this point, throw an error because we can't do anything with it
    if not lf.isStr(name) or not lf.isTbl(options) then
        lx.throw(\InvalidArgumentException, 'One of the columns in your ' .. self.config:getOption('name') .. ' model configuration file is invalid')
    end
    --in any case, make sure the 'column_name' option is set
    options['column_name'] = name
    
    return options
end

-- Gets the column objects.
-- @return table

function _M:getColumns()

    local object
    --make sure we only run this once and then return the cached version
    if not sizeof(self.columns) then
        for name, options in pairs(self.config:getOption('columns')) do
            --if only a string value was supplied, may sure to turn it into an table
            object = self:make(self:parseOptions(name, options))
            self.columns[object:getOption('column_name')] = object
        end
    end
    
    return self.columns
end

-- Gets the column objects as an integer-indexed table.
-- @return table

function _M:getColumnOptions()

    --make sure we only run this once and then return the cached version
    if not sizeof(self.columnOptions) then
        for _, column in pairs(self:getColumns()) do
            tapd(self.columnOptions, column:getOptions())
        end
    end
    
    return self.columnOptions
end

-- Gets the columns that are on the model's table (i.e. not related or computed).
-- @param table fields
-- @return table

function _M:getIncludedColumns(fields)

    local model
    --make sure we only run this once and then return the cached version
    if not sizeof(self.includedColumns) then
        model = self.config:getDataModel()
        for _, column in pairs(self:getColumns()) do
            if column:getOption('is_related') then
                self.includedColumns = tb.merge(self.includedColumns, column:getIncludedColumn())
            elseif not column:getOption('is_computed') then
                self.includedColumns[column:getOption('column_name')] = model:getTable() .. '.' .. column:getOption('column_name')
            end
        end
        --make sure the table key is included
        if not self.validator:arrayGet(self.includedColumns, model:getKeyName()) then
            self.includedColumns[model:getKeyName()] = model:getTable() .. '.' .. model:getKeyName()
        end
        --make sure any belongs_to fields that aren't on the columns list are included
        for _, field in pairs(fields) do
            if is_a(field, 'Frozennode\\Administrator\\Fields\\Relationships\\BelongsTo') then
                self.includedColumns[field:getOption('foreign_key')] = model:getTable() .. '.' .. field:getOption('foreign_key')
            end
        end
    end
    
    return self.includedColumns
end

-- Gets the columns that are relationship columns.
-- @return table

function _M:getRelatedColumns()

    --make sure we only run this once and then return the cached version
    if not sizeof(self.relatedColumns) then
        for _, column in pairs(self:getColumns()) do
            if column:getOption('is_related') then
                self.relatedColumns[column:getOption('column_name')] = column:getOption('column_name')
            end
        end
    end
    
    return self.relatedColumns
end

-- Gets the columns that are computed.
-- @return table

function _M:getComputedColumns()

    --make sure we only run this once and then return the cached version
    if not sizeof(self.computedColumns) then
        for _, column in pairs(self:getColumns()) do
            if not column:getOption('is_related') and column:getOption('is_computed') then
                self.computedColumns[column:getOption('column_name')] = column:getOption('column_name')
            end
        end
    end
    
    return self.computedColumns
end

return _M

