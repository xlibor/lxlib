
local _M = {
    _cls_ = '@sqlTableFields'
}
local mt = { __index = _M }

local lx = require('lxlib')
local app, lf, tb, str = lx.kit()
local pub = require('lxlib.db.pub')
local dbInit = lx.db

local tconcat = table.concat

function _M:new(table)

    local this = {
        createMode = false,
        items = lx.col(),
        keyItems = lx.col(),
        table = table
    }

    setmetatable(this, mt)

    return this
end

function _M:addField(fieldName, dataType, size)

    local field

    if lf.isObj(fieldName) then
        field = fieldName
        fieldName = field.name
    else
        field = dbInit.sqlTableField(fieldName, dataType)
        if size then
            field:size(size)
        end
    end

    self.items:add(field, fieldName)

    return field
end

function _M:add(fieldName, dataType, size)

    self:ensureAlterModeValid('add')

    return self:addField(fieldName, dataType, size):mode('add')
end

function _M:alter(fieldName, dataType, size)

    self:ensureAlterModeValid('alter')
    return self:addField(fieldName, dataType, size):mode('alter')
end

function _M:dropColumn(fieldName)

    self:ensureAlterModeValid('drop')
    field = dbInit.sqlTableField(fieldName)
    field:mode('drop')
    self.items:add(field, fieldName)

    return field
end

_M.drop = _M.dropColumn

function _M:dropSoftDeletes()

    return self:dropColumn('deleted_at')
end

function _M:dropForeign(index)

    self:ensureAlterModeValid('drop')
    local field = dbInit.sqlTableField(index)
    field:mode('drop'):foreign()
    self.keyItems:add(field, index)

    return field
end

function _M:sql(dbType)
 
    local sql = {}
    local items = self.items
    local alterMode = self.alterMode
    local onlyFieldName = (alterMode == 'drop')
    local strMode
    local showMode
 
    if alterMode == 'mix' then
        showMode = true
    else
        tapd(sql, '(')
    end

    local keyFields = {}
    local count = self:count()
    local keyCount = self:keyCount()

    local field
    if count > 0 then
        for i = 1, count do
            field = items:itemByIdx(i)
            tapd(sql, field:sql(dbType, showMode))
            if field:isKey() then
                tapd(sql, ', ')
                tapd(sql, field:keySql(dbType, showMode, self.table))
            end
            if i < count then tapd(sql, ', ') end    
        end
    elseif keyCount > 0 then

    else
        error('no column added')
    end

    if keyCount > 0 then
        if count > 0 then
            tapd(sql, ', ')
        end
        for i = 1, keyCount do
            field = self.keyItems:itemByIdx(i)
            tapd(sql, field:keySql(dbType, showMode, self.table))
            if i < keyCount then tapd(sql, ', ') end    
        end
    end

    if not showMode then
        tapd(sql, ')')
    end

    local strSql = tconcat(sql)
 
    return strSql
end

function _M:item(fieldName)

    local field = self.items:get(fieldName)

    return field
end

function _M:count()

    return self.items:count()
end

function _M:keyCount()

    return self.keyItems:count()
end

function _M:exists(fieldName)

    return self.items:exists(fieldName)
end

function _M:ensureAlterModeValid(alterMode)

    if self.createMode then
        if alterMode ~= 'add' then
            error('invalid alter mode, must be add')
        end
    end
    if self.alterMode then 
        if alterMode ~= self.alterMode then
            self.alterMode = 'mix'
        end
    else
        self.alterMode = alterMode
    end
end

function _M:unique(columns, name)

    return self:addKeyField('unique', columns):unique()
end

function _M:index(columns, name)

    return self:addKeyField('index', columns):index()
end

function _M:primary(columns, name)

    return self:addKeyField('primary', columns):primary()
end

function _M:foreign(columns, name)

    return self:addKeyField('foreign', columns):foreign()
end

function _M:addKeyField(keyType, columns, name)

    columns = lf.needList(columns)

    local field = dbInit.sqlTableField(columns)

    self.keyItems:add(
        field, str.lower(str.join(columns, '_')) .. '_' .. keyType
    )
    if name then
        field:keyName(name)
    end

    return field
end

function _M:morphs(name, indexName)

    local idName = name .. '_id'
    local typeName = name .. '_type'
    self:unsignedInteger(idName)
    self:string(typeName)

    self:index({idName, typeName}, indexName)
end

function _M:char(column, size)

    size = size or 255
    return self:add(column, 'char', size)
end

function _M:string(column, size)

    size = size or 255
    return self:add(column, 'string', size)
end

function _M:text(column)

    return self:add(column, 'text')
end

function _M:char(column, size)

    size = size or 255
    return self:add(column, 'char', size)
end

function _M:mediumText(column)

    return self:add(column, 'mediumText')
end

_M.mediumtext = mediumText

function _M:longText(column)

    return self:add(column, 'longText')
end

_M.longtext = _M.longText

function _M:blob(column)

    return self:add(column, 'blob')
end

function _M:mediumBlob(column)

    return self:add(column, 'mediumBlob')
end

function _M:longBlob(column)

    return self:add(column, 'longBlob')
end

function _M:increments(column)

    return self:add(column, 'integer')
        :autoIncrement(true)
        :unsigned(true)
end

function _M:bigIncrements(column)

    return self:add(column, 'bigInteger')
        :autoIncrement(true)
        :unsigned(true)
end

function _M:integer(column, autoIncrement, unsigned)

    autoIncrement = lf.needFalse(autoIncrement)
    unsigned = lf.needFalse(unsigned)
    
    return self:add(column, 'integer')
        :autoIncrement(autoIncrement)
        :unsigned(unsigned)
end

function _M:unsignedInteger(column, autoIncrement)

    return self:add(column, 'integer')
        :autoIncrement(autoIncrement)
        :unsigned(true)
end

function _M:tinyInteger(column, autoIncrement, unsigned)

    return self:add(column, 'tinyInteger')
        :autoIncrement(autoIncrement)
        :unsigned(unsigned)
end

_M.tinyinteger = _M.tinyInteger

function _M:smallInteger(column, autoIncrement, unsigned)

    return self:add(column, 'smallInteger')
        :autoIncrement(autoIncrement)
        :unsigned(unsigned)
end

_M.smallinteger = _M.smallInteger

function _M:mediumInteger(column, autoIncrement, unsigned)

    return self:add(column, 'mediumInteger')
        :autoIncrement(autoIncrement)
        :unsigned(unsigned)
end

_M.mediuminteger = _M.mediumInteger

function _M:bigInteger(column, autoIncrement, unsigned)

    return self:add(column, 'bigInteger')
        :autoIncrement(autoIncrement)
        :unsigned(unsigned)
end

_M.biginteger = _M.bigInteger

function _M:float(column, total, places)

    total = total or 8
    places = places or 2
    return self:add(column, 'float')
        :total(total)
        :places(places)
end

function _M:double(column, total, places)

    return self:add(column, 'double')
        :total(total)
        :places(places)
end

function _M:decimal(column, total, places)

    total = total or 8
    places = places or 2
    return self:add(column, 'decimal')
        :total(total)
        :places(places)
end

function _M:boolean(column)

    return self:add(column, 'boolean')
end

function _M:enum(column, allowed)

    return self:add(column, 'enum'):allowed(allowed)
end

function _M:json(column)

    return self:add(column, 'json')
end

function _M:jsonb(column)

    return self:add(column, 'jsonb')
end

function _M:json(column)

    return self:add(column, 'json')
end

function _M:date(column)

    return self:add(column, 'date')
end

function _M:dateTime(column)

    return self:add(column, 'dateTime')
end

function _M:dateTimeTz(column)

    return self:add(column, 'dateTimeTz')
end

function _M:time(column)

    return self:add(column, 'time')
end

function _M:timeTz(column)

    return self:add(column, 'timeTz')
end

function _M:timestamp(column)

    return self:add(column, 'timestamp')
end

function _M:timestampTz(column)

    return self:add(column, 'timestampTz')
end

function _M:timestamps()

    self:timestamp('created_at'):nullable()
    self:timestamp('updated_at'):nullable()
end

function _M:timestampsTz()

    self:timestampTz('created_at'):nullable()
    self:timestampTz('updated_at'):nullable()
end

function _M:softDeletes()

    self:timestamp('deleted_at'):nullable()
end

_M.softDelete = _M.softDeletes

function _M:binary(column)

    return self:add(column, 'binary')
end

function _M:uuid(column)

    return self:add(column, 'uuid')
end

function _M:ipAddress(column)

    return self:add(column, 'ipAddress')
end

function _M:macAddress(column)

    return self:add(column, 'macAddress')
end

function _M:rememberToken()

    self:string('remember_token', 100):nullable()
end

return _M

