
local _M = {
    _cls_ = '@sqlTableField'
}
local mt = { __index = _M }

local lx = require('lxlib')
local app, lf, tb, str = lx.kit()
local pub = require('lxlib.db.pub')
local fmt = string.format

local intList = {
    integer = 1, bigInteger = 1, smallInteger = 1, tinyInteger =1
}
local charList = {
    char = 1, unicodeChar = 1, varchar = 1, unicodeVarchar = 1
}

local tconcat = table.concat 

function _M:new(name, dataType, alterMode)

    local attrs = {
        name = name,
        dataType = dataType or 'varchar',
        size = 10,
        precision = 18,
        scale = 0,
        acceptsNull = false,
        unsigned = false
    }

    local this = {
        alterMode = alterMode,
        attrs = attrs,
     }

    setmetatable(this, mt)

    return this
end

function _M:acceptsNull(value)

    self.attrs.acceptsNull = lf.needTrue(value)
    return self
end

_M.nullable = _M.acceptsNull

function _M:increments(value)

    self.attrs.autoIncrement = value
    self:nullable(false)
    return self
end

_M.incr = _M.increments
_M.autoIncrement = _M.increments

function _M:unsigned(value)

    value = lf.needTrue(value)
    self.attrs.unsigned = value

    return self
end

function _M:afterColumn(value)

    self.attrs.afterColumn = value
    return self
end

_M.after = _M.afterColumn

function _M:allowed(value)

    self.attrs.allowed = value
    return self
end

function _M:name(value)

    self.attrs.name = value
    return self
end

function _M:dataType(value)

    self.attrs.dataType = value
    return self
end

function _M:default(value)

    self.attrs.default = value
    return self
end

function _M:comment(value)

    self.attrs.comment = value
    return self
end

function _M:keyType(value)

    if value == 'primary' or value == 'unique' then
        self:acceptsNull(false)
    end

    self.attrs.keyType = value

    return self
end

function _M:keyName(value)

    self.attrs.keyName = value

    return self
end

function _M:unique()

    self:keyType('unique')

    return self
end

function _M:index()

    self:keyType('index')

    return self
end

function _M:primary()

    self:keyType('primary')

    return self
end

function _M:foreign()

    self:keyType('foreign')

    return self
end

function _M:references(value)

    self.attrs.references = value

    return self
end

function _M:on(value)

    self.attrs.on = value

    return self
end

function _M:onDelete(value)

    self.attrs.onDelete = value
    return self
end

function _M:onUpdate(value)

    self.attrs.onUpdate = value
    
    return self
end

function _M:precision(value)

    self.attrs.precision = value
    return self
end

_M.total = _M.precision

function _M:scaleLength(value)

    self.attrs.scale = value
    return self
end

_M.scale = _M.scaleLength
_M.place = _M.scaleLength
_M.places = _M.place

function _M:size(value)

    if value <= 0 then
        error('column size must greater than 0')
    end
    self.attrs.size = value

    return self
end

function _M:useCurrent()

    self.attrs.useCurrent = true

    return self
end

function _M:newName(value)

    self:alterMode('rename')
    self.attrs.newName = value
end

_M.rename = _M.newName

function _M:alterMode(value)

    self.attrs.alterMode = value

    return self
end

_M.mode = _M.alterMode

function _M:change()

    self.attrs.alterMode = 'alter'
end

function _M:ensureCharDataType()

    local dataType = self.attrs.dataType

    return charList[dataType] and true or false
end

function _M:ensureIntegerDataType()

    if not self:isIntegerDataType() then
        error('column type must be integer')
    end
end

function _M:ensureDecimalDataType()

    local dataType = self.attrs.dataType

    if dataType ~= 'decimal' then
        error('column type must be decimal')
    end
end

function _M:isIntegerDataType()

    local dataType = self.attrs.dataType
    return intList[dataType] and true or false
end

function _M:defaultValueIsSet()

    return lf.isset(self.attrs.default)
end

function _M:sql(dbType, showMode)

    local sql
    local alterMode = self.attrs.alterMode
    local fieldName = self.attrs.name
    if not fieldName then
        error('filed name has not been set')
    end

    fieldName = pub.sqlWrapName(fieldName, dbType)

    if (not showMode) and alterMode == 'drop' then
        sql = fieldName
    else
        local dataType = self.attrs.dataType
        dataType = self:dataTypeString(dbType, dataType)
        local columnOptions = self:columnOptions(dbType)
        local baseInfo = fieldName..' '..dataType..' '..columnOptions
        if alterMode and showMode then
            if alterMode == 'add' then
                sql = 'add '.. baseInfo
            elseif alterMode == 'alter' then
                sql = 'modify '.. baseInfo
            elseif alterMode == 'change' or alterMode == 'rename' then
                local newName = self.attrs.newName
                sql = 'change '..fieldName..' '..newName..' '..dataType..' '..columnOptions
            elseif alterMode == 'drop' then
                sql = 'drop column ' .. fieldName
            end
        else
            sql = baseInfo
        end
    end

    return sql
end
 
function _M:columnOptions(dbType)

    local options = {}
    local alterMode = self.attrs.alterMode
    local acceptsNull = self.attrs.acceptsNull
    local dataType = self.attrs.dataType
    local keyType = self.attrs.keyType
    local unsigned = self.attrs.unsigned
    local default = self.attrs.default
    local autoIncrement = self.attrs.autoIncrement
    local comment = self.attrs.comment
    local asFirst = self.attrs.asFirst
    local afterColumn = self.attrs.afterColumn

    if unsigned then
        tapd(options, 'unsigned')
    end

    if acceptsNull then
        tapd(options, 'null')
    else
        tapd(options, 'not null')
    end

    if self:defaultValueIsSet() then
        if keyType ~= 'primary' then
            tapd(options, 'default ' .. pub.sqlConvertValue(default, dbType))
        end
    end

    if self:isIntegerDataType() and autoIncrement then
        if dbType == 'sqlite' then
            tapd(options, 'identity')
        elseif dbType == 'mysql' then
            tapd(options, 'auto_increment')
            if not keyType then
                self.attrs.keyType = 'primary'
            end
        end
    end

    if keyType == 'primary' then
        -- tapd(options, 'primary key')
    elseif keyType == 'unique' then
        -- tapd(options, 'unique')
    end

    if comment then
        if dbType == 'mysql' then
            tapd(options, "comment '" .. comment .. "'")
        end
    end

    if asFirst then
        if dbType == 'mysql' then
            tapd(options, "first")
        end
    end

    if afterColumn then
        if dbType == 'mysql' then
            tapd(options, "after " .. afterColumn)
        end
    end

    local strOptions = tconcat(options, ' ')

    return strOptions
end

function _M:keySql(dbType, showMode, tableName)

    local sql = ''
    local keyType = self.attrs.keyType
    local keyName = self.attrs.keyName
    local fieldName = self.attrs.name

    local alterMode = self.attrs.alterMode
    if (not showMode) and alterMode == 'drop' then
    else
        if alterMode and showMode then
            if alterMode == 'add' then
                sql = 'add '
            elseif alterMode == 'alter' then
                sql = 'modify '
            elseif alterMode == 'change' or alterMode == 'rename' then
                sql = 'change '
            elseif alterMode == 'drop' then

                if keyType == 'foreign' then
                    sql = 'drop foreign key ' .. fieldName
                elseif keyType == 'index' or keyType == 'unique' then
                    sql = 'drop index ' .. fieldName
                elseif keyType == 'primary' then
                    sql = 'drop primary'
                end

                return sql
            end
        else

        end
    end

    local fieldNames = lf.needList(self.attrs.name)

    if not fieldNames then
        error('filed name has not been set')
    end

    local indexName = self:createIndexName(keyType, fieldNames, tableName)
    indexName = pub.sqlWrapName(indexName, dbType)

    local fieldName

    if not keyName then
        local fields = {}
        for i, v in ipairs(fieldNames) do
            tapd(fields, pub.sqlWrapName(v, dbType))
        end
        fieldName = str.join(fields, ',')
    else
        fieldName = keyName
    end

    if keyType == 'index' then
        keyType = ''
    elseif keyType == 'primary' then
        indexName = ''
    elseif keyType == 'foreign' then
        sql = sql .. ' constraint ' .. indexName .. ' '
        indexName = ''
    end

    sql = sql .. keyType .. ' key '
        .. indexName
        .. ' (' .. fieldName .. ')'

    if keyType == 'foreign' then
        local references = self.attrs.references
        local onTable = self.attrs.on

        sql = sql .. ' references ' .. pub.sqlWrapName(onTable, dbType)
            .. ' (' .. pub.sqlWrapName(references, dbType) .. ')'
        local onDelete = self.attrs.onDelete
        local onUpdate = self.attrs.onUpdate
        if onDelete then
            sql = sql .. ' on delete ' .. onDelete
        end
        if onUpdate then
            sql = sql .. ' on update ' .. onUpdate
        end
    end

    return sql
end

function _M:createIndexName(type, columns, tableName)

    local index = str.lower(tableName .. '_' .. str.join(columns, '_') .. '_' .. type)
    
    return index
    -- return str.replace(index, {'-', '.'}, '_')
end

function _M:dataTypeString(dbType, dataType)

    local size = self.attrs.size or 0

    local scale = self.attrs.scale or 0
    local precision = self.attrs.precision or 0
    local useCurrent = self.attrs.useCurrent or false

    dataType = str.lower(dataType)

    if dataType == 'tinyinteger' then
        if dbType == 'sqlite' then
            strDataType = "integer"
        elseif dbType == 'mysql' then
            strDataType = "tinyint"
        end
    elseif dataType == 'smallinteger' then
        if dbType == 'sqlite' then
            strDataType = "integer"
        elseif dbType == 'mysql' then
            strDataType = "smallint"
        end
    elseif dataType == 'integer' then
        if dbType == 'sqlite' then
            strDataType = "integer"
        elseif dbType == 'mysql' then
            strDataType = "int"
            if size > 0 then
                strDataType = fmt('int(%s)', size)
            end
        end
    elseif dataType == 'biginteger' then
        if dbType == 'sqlite' then
            strDataType = "integer"
        elseif dbType == 'mysql' then
            strDataType = "bigint"
        end
    elseif dataType == 'mediuminteger' then
        if dbType == 'sqlite' then
            strDataType = "integer"
        elseif dbType == 'mysql' then
            strDataType = "mediumint"
        end
    elseif dataType == 'decimal' then
        if dbType == 'sqlite' then
            strDataType = 'numeric'
        elseif dbType == 'mysql' then
            strDataType = fmt('decimal(%s, %s)', precision, scale)
        end
    elseif dataType == 'real' then
        if dbType == 'sqlite' then
            strDataType = "real"
        elseif dbType == 'mysql' then
            strDataType = "float"
        end
    elseif dataType == 'float' then
        if dbType == 'sqlite' then
            strDataType = "float"
        elseif dbType == 'mysql' then
            strDataType = "double"
            if precision > 0 or scale > 0 then
                strDataType = fmt('double(%s, %s)', precision, scale)
            end
        end
    elseif dataType == 'double' then
        if dbType == 'sqlite' then
            strDataType = "float"
        elseif dbType == 'mysql' then
            strDataType = "double"
            if precision > 0 or scale > 0 then
                strDataType = fmt('double(%s, %s)', precision, scale)
            end
        end
    elseif dataType == 'money' then
        if dbType == 'sqlite' then
            strDataType = "numeric"
        elseif dbType == 'mysql' then
            strDataType = "decimal(19,4)"
        end
    elseif dataType == 'char' then
        if dbType == 'sqlite' then
            strDataType = 'varchar'
        elseif dbType == 'mysql' then
            strDataType = fmt('char(%s)', size)
        end
    elseif dataType == 'string' then
        if dbType == 'sqlite' then
            strDataType = 'varchar'
        elseif dbType == 'mysql' then
            strDataType = fmt('varchar(%s)', size)
        end
    elseif dataType == 'varchar' then
        if dbType == 'sqlite' then
            strDataType = 'varchar'
        elseif dbType == 'mysql' then
            strDataType = fmt('varchar(%s)', size)
        end
    elseif dataType == 'text' then
        if dbType == 'sqlite' then
            strDataType = "text"
        elseif dbType == 'mysql' then
            strDataType = "text"
        end
    elseif dataType == 'mediumtext' then
        if dbType == 'sqlite' then
            strDataType = "text"
        elseif dbType == 'mysql' then
            strDataType = "mediumtext"
        end
    elseif dataType == 'longtext' then
        if dbType == 'sqlite' then
            strDataType = "text"
        elseif dbType == 'mysql' then
            strDataType = "longtext"
        end
    elseif dataType == 'blob' then
        if dbType == 'sqlite' then
            strDataType = "blob"
        elseif dbType == 'mysql' then
            strDataType = "blob"
        end
    elseif dataType == 'mediumblob' then
        if dbType == 'sqlite' then
            strDataType = "blob"
        elseif dbType == 'mysql' then
            strDataType = "mediumblob"
        end
    elseif dataType == 'longblob' then
        if dbType == 'sqlite' then
            strDataType = "blob"
        elseif dbType == 'mysql' then
            strDataType = "longblob"
        end
    elseif dataType == 'date' then
        if dbType == 'sqlite' or dbType == 'mysql' then
            strDataType = "date"
        end
    elseif dataType == 'datetime' or dataType == 'datetimetz' then
        if dbType == 'sqlite' or dbType == 'mysql' then
            strDataType = "datetime"
        end
    elseif dataType == 'time' or dataType == 'timetz' then
        if dbType == 'sqlite' or dbType == 'mysql' then
            strDataType = "time"
        end
    elseif dataType == 'timestamp' or dataType == 'timestamptz'then
        if dbType == 'sqlite' then
            error('not supported timestamp')
        elseif dbType == 'mysql' then
            strDataType = "timestamp"
            if not self.attrs.acceptsNull and not self.attrs.default
                and not useCurrent then

                self.attrs.default = '0000-00-00 00:00:00'
            end
        end
        if useCurrent then
            strDataType = strDataType .. ' default CURRENT_TIMESTAMP'
        end
    elseif dataType == 'boolean' then
        if dbType == 'sqlite' then
            strDataType = "tinyint(1)"
        elseif dbType == 'mysql' then
            strDataType = "tinyint(1)"
        end
    elseif dataType == 'binary' then
        if dbType == 'sqlite' then
            strDataType = "oleobject"
        elseif dbType == 'mysql' then
            strDataType = "blob"
        end
    elseif dataType == 'varbinary' then
        if dbType == 'sqlite' then
            strDataType = "oleobject"
        elseif dbType == 'mysql' then
            strDataType = "blob"
        end
    elseif dataType == 'enum' then
        if dbType == 'sqlite' then
            strDataType = "varchar"
        elseif dbType == 'mysql' then
            local allowed = self.attrs.allowed
            strDataType = fmt("enum('%s')", str.join(allowed, "', '"))
        end
    elseif dataType == 'json' then
        if dbType == 'sqlite' then
            strDataType = "text"
        elseif dbType == 'mysql' then
            strDataType = "json"
        end
    elseif dataType == 'jsonb' then
        if dbType == 'sqlite' then
            strDataType = "text"
        elseif dbType == 'mysql' then
            strDataType = "jsonb"
        end
    elseif dataType == 'uuid' then
        if dbType == 'sqlite' then
            strDataType = "varchar"
        elseif dbType == 'mysql' then
            strDataType = "char(36)"
        end
    elseif dataType == 'ipaddress' then
        if dbType == 'sqlite' then
            strDataType = "varchar"
        elseif dbType == 'mysql' then
            strDataType = "char(45)"
        end
    elseif dataType == 'macaddress' then
        if dbType == 'sqlite' then
            strDataType = "varchar"
        elseif dbType == 'mysql' then
            strDataType = "char(17)"
        end
    elseif dataType == 'image' then
        if dbType == 'sqlite' then
            strDataType = "image"
        elseif dbType == 'mysql' then
            strDataType = "longblob"
        end
    end

    return strDataType
end

function _M:getKeyType()

    return self.attrs.keyType
end

function _M:isKey()

    return lf.notEmpty(self.attrs.keyType)
end

function _M:getName()

    return self.attrs.name
end

return _M

