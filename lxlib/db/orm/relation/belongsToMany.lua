
local lx, _M = oo{
    _cls_   = '',
    _ext_   = 'relation',

    selfJoinCount = 0
}

local app, lf, tb, str = lx.kit()
local Query = lx.use('orm.query')
local ssub = string.sub

local static

function _M._init_(this)

    static = this.static
end

function _M:ctor(query, parent, table, foreignKey, otherKey, relationName)

    self.pivotColumns = {}
    self.pivotWheres = {}
    self.pivotWhereIns = {}
    self.table = table
    self.otherKey = otherKey
    self.foreignKey = foreignKey
    self.relationName = relationName
    self.pivotCreatedAt = nil
    self.pivotUpdatedAt = nil

    self.__skip = true
    self:__super(_M, 'ctor', query, parent)
end

function _M:getResults()

    return self:get()
end

function _M:wherePivot(column, operator, value, boolean)

    operator = operator or '='
    boolean = boolean or 'and'
    tapd(self.pivotWheres, {column, operator, value, boolean})

    return self:where(self.table..'.'..column, operator, value, boolean)
end

function _M:wherePivotIn(column, values, boolean, isNot)

    operator = operator or '='
    boolean = boolean or 'and'
    isNot = isNot or false
    tapd(self.pivotWhereIns, {column, values, boolean, isNot})

    return self:whereIn(self..table..'.'..column, values, boolean, isNot)
end

function _M:orWherePivot(column, operator, value)

    operator = operator or '='

    return self:wherePivot(column, operator, value, 'or')
end

function _M:orWherePivotIn(column, values)

    return self:wherePivotIn(column, values, 'or')
end

function _M:first(columns)

    local results = self:take(1):get(columns)

    return results[1]
end

function _M:firstOrFail(columns)

    local model = self:first(columns)
    if model then
        return model
    end

    lx.throw('modelNotFoundException'):setModel(self.parent.__cls)
end

function _M:get(columns)

    columns = self.query:getBuilder().columns and {} or columns

    local selectColumns = self:getSelectColumns(columns)

    local query = self.query:applyScopes()

    local models = query:addSelect(selectColumns):getModels()

    self:hydratePivotRelation(models)

    if #models > 0 then
        models = query:eagerLoadRelations(models)
    end

    Query.setModelsMt(models)

    return models
end

function _M:paginate(perPage, columns, pageName, page)

    pageName = pageName or 'page'
    self.query:addSelect(self:getSelectColumns(columns))

    local paginator = self.query:paginate(perPage, columns, pageName, page)

    self:hydratePivotRelation(paginator.items:all())

    return paginator
end

function _M:simplePaginate(perPage, columns, pageName)

    pageName = pageName or 'page'

    self.query:addSelect(self:getSelectColumns(columns))

    local paginator = self.query:simplePaginate(perPage, columns, pageName)

    self:hydratePivotRelation(paginator.items:all())

    return paginator
end

function _M:chunk(count, callback)

    self.query:addSelect(self:getSelectColumns())

    return self.query:chunk(count, function(results)
        self:hydratePivotRelation(results:all())

        return callback(results)
    end)
end

function _M.__:hydratePivotRelation(models)
    
    local pivot
    for _, model in pairs(models) do
        pivot = self:newExistingPivot(self:cleanPivotAttrs(model))

        model:setRelation('pivot', pivot)
    end
end

function _M.__:cleanPivotAttrs(model)

    local values = {}

    for key, value in pairs(model:getAttrs()) do
        if str.startsWith(key, 'pivot_') then 
            values[ssub(key, 7)] = value
            model[key] = nil
        end
    end

    return values
end

function _M:addConstraints()

    self:setJoin()

    if static.constraints then

        self:setWhere()
    end
end

function _M:getRelationQuery(query, parent, columns)

    if parent:getQuery():baseTable() == query:getQuery():baseTable() then

        return self:getRelationQueryForSelfJoin(query, parent, columns)
    end

    self:setJoin(query)

    return self:__super(_M, 'getRelationQuery', query, parent, columns)
end

function _M:getRelationQueryForSelfJoin(query, parent, columns)

    query:select(columns)

    local hash = self:getRelationCountHash()

    query:tableAs(hash)

    self.related:setTable(hash)

    self:setJoin(query)

    return self:__super(_M, 'getRelationQuery', query, parent, columns)
end

function _M:getRelationCountHash()

    _M.selfJoinCount = _M.selfJoinCount + 1

    return 'laravel_reserved_'.._M.selfJoinCount
end

function _M.__:getSelectColumns(columns)

    if tb.count(columns) == 0 then
        columns = {self.related:getTable()..'.*'}
    end
    local t = self:getAliasedPivotColumns()

    return tb.merge(columns, t)
end

function _M.__:getAliasedPivotColumns()

    local defaults = {self.foreignKey, self.otherKey}

    local columns = {}

    for _, column in ipairs(tb.merge(defaults, self.pivotColumns)) do
        tapd(columns, {self.table..'.'..column, 'pivot_'..column})
    end

    return tb.unique(columns, nil, function(v)
        if type(v) == 'table' then
            return v[1]
        else
            return v
        end
    end)
end

function _M.__:hasPivotColumn(column)

    return tb.contains(self.pivotColumns, column)
end

function _M.__:setJoin(query)

    query = query or self.query

    local baseTable = self.related:getTable()

    local key = baseTable .. '.' .. self.related:getKeyName()

    query:join(self.table):on(key, '=', self:getOtherKey())

    return self
end

function _M.__:setWhere()

    local foreign = self:getForeignKey()

    self.query:where(foreign, '=', self.parent:getKey())

    return self
end

function _M:addEagerConstraints(models)

    self.query:whereIn(self:getForeignKey(), self:getKeys(models))
end

function _M:initRelation(models, relation)

    for _, model in ipairs(models) do
        -- todo: may replace {} to self.related:col()
        model:setRelation(relation, {})
    end

    return models
end

function _M:match(models, results, relation)

    local dictionary = self:buildDictionary(results)

    local key, value, col
    for _, model in ipairs(models) do
        key = model:getKey()
        value = dictionary[key]
        if value then
            model:setRelation(relation, value)
        end
    end

    return models
end

function _M.__:buildDictionary(results)

    local foreign = self.foreignKey
    
    local dictionary = {}

    local key
    for _, result in ipairs(results) do
        key = result.pivot[foreign]
        tb.mapd(dictionary, key, result)
    end

    return dictionary
end

function _M:touch()

    local key = self:getRelated():getKeyName()

    local columns = self:getRelatedFreshUpdate()

    local ids = self:getRelatedIds()

    if #ids > 0 then
        self:getRelated():newQuery():whereIn(key, ids):update(columns)
    end
end

function _M:getRelatedIds()

    local related = self:getRelated()

    local fullKey = related:getQualifiedKeyName()

    return self:getQuery():select(fullKey):pluck(related:getKeyName())
end

function _M:save(model, joining, touch)

    joining = joining or {}
    touch = lf.needTrue(touch)

    model:save({touch =  false})

    self:attach(model:getKey(), joining, touch)

    return model
end

function _M:saveMany(models, joinings)

    joinings = joinings or {}

    for key, model in pairs(models) do 
        self:save(model, tb.get(joinings, key), false)
    end

    self:touchIfTouching()

    return models
end

function _M:find(id, columns)

    if lf.isTbl(id) then
        return self:findMany(id, columns)
    end

    self:where(self:getRelated():getQualifiedKeyName(), '=', id)

    return self:first(columns)
end

function _M:findMany(ids, columns)

    if lf.isEmpty(ids) then
        return {}
    end

    self:whereIn(self:getRelated():getQualifiedKeyName(), ids)

    return self:get(columns)
end

function _M:findOrFail(id, columns)

    local result = self:find(id, columns)

    if lf.isTbl(id) then
        if #result == #tb.unique(id) then
            return result
        end
    elseif result then
        return result
    end

    lx.throw('modelNotFoundException'):setModel(self.parent.__cls)
end

function _M:findOrNew(id, columns)

    local instance = self:find(id, columns)

    if not instance then
        instance = self:getRelated():newInstance()
    end

    return instance
end

function _M:firstOrNew(attrs)

    local instance = self:where(attrs):first()
    if not instance then 
        instance = self.related:newInstance(attrs)
    end

    return instance
end

function _M:firstOrCreate(attrs, joining, touch)

    joining = joining or {}
    touch = lf.needTrue(touch)

    local instance = self:where(attrs):first()
    if not instance then 
        instance = self:create(attrs, joining, touch)
    end

    return instance
end

function _M:updateOrCreate(attrs, values, joining, touch)

    values = values or {}
    joining = joining or {}
    touch = lf.needTrue(touch)
    local instance = self:where(attrs):first()

    if not instance then
        return self:create(values, joining, touch)
    end

    instance:fill(values)

    instance:save({touch = false})

    return instance
end

function _M:create(attrs, joining, touch)

    joining = joining or {}
    touch = lf.needTrue(touch)

    local instance = self.related:newInstance(attrs)

    instance:save({touch = false})

    self:attach(instance:getKey(), joining, touch)

    return instance
end

function _M:createMany(records, joinings)

    joining = joining or {}
    local instances = {}

    for key, record in pairs(records) do
        tapd(instances, self:create(record, tb.get(joinings, key), false))
    end

    self:touchIfTouching()

    return instances
end

function _M:toggle(ids)

    local changes = {
        attached = {}, detached = {}
    }

    if ids:__is('model') then 
        ids = ids:getKey()
    end

    if ids:__is('col') then 
        ids = ids:modelKeys()
    end

    local current = self:newPivotQuery():pluck(self.otherKey):all()

    local records = self:formatRecordsList(ids)

    local detach = tb.values(tb.intersect(
        current, tb.keys(records)
    ))

    if #detach > 0 then
        self:detach(detach, false)
        changes.detached = self:castKeys(detach)
    end
    
    local attach = tb.diffKey(records, tb.flip(detach))

    if #attach > 0 then
        self:attach(attach, {}, false)

        changes.attached = tb.keys(attach)
    end

    if #changes.attached > 0 or #changes.detached > 0 then
        self:touchIfTouching()
    end

    return changes
end

function _M:syncWithoutDetaching(ids)

    return self:sync(ids, false)
end

function _M:sync(ids, detaching)

    detaching = lf.needTrue(detaching)

    local changes = {
        attached = {}, detached = {}, updated = {}
    }

    if lf.isObj(ids) and ids:__is('col') then
        ids = ids:modelKeys()
    end

    local current = self:newPivotQuery():pluck(self.otherKey)
    local records = self:formatRecordsList(ids)
    local detach = tb.diff(current, tb.keys(records))

    if detaching and #detach > 0 then
        self:detach(detach)

        changes.detached = self:castKeys(detach)
    end
    
    changes = tb.merge(
        changes, self:attachNew(records, current, false)
    )

    if #changes.attached > 0 or #changes.updated > 0 then
        self:touchIfTouching()
    end

    return changes
end

function _M.__:formatRecordsList(records)

    local results = {}

    for id, attrs in pairs(records) do 
        if not lf.isTbl(attrs) then
            id, attrs = attrs, {}
        end

        results[id] = attrs
    end

    return results
end

function _M.__:attachNew(records, current, touch)

    touch = lf.needTrue(touch)

    local changes = { attached = {}, updated = {} }

    for id, attrs in pairs(records) do

        if not tb.contains(current, id) then
            self:attach(id, attrs, touch)
            id = lf.isNum(id) and tonumber(id) or tostring(id)
            tapd(changes.attached, id)
        elseif #attrs > 0 and self:updateExistingPivot(id, attrs, touch) then
            id = lf.isNum(id) and tonumber(id) or tostring(id)
            tapd(changes.updated, id)
        end
    end

    return changes
end

function _M.__:castKeys(keys)

    return tb.map(keys, function(v) 
        return lf.isNum(v) and tonumber(v) or tostring(v)
    end)
end

function _M:updateExistingPivot(id, attrs, touch)

    touch = lf.needTrue(touch)

    if tb.contains(self.pivotColumns, self:updatedAt()) then
        attrs = self:setTimestampsOnAttach(attrs, true)
    end

    local updated = self:newPivotStatementForId(id):update(attrs)

    if touch then
        self:touchIfTouching()
    end

    return updated
end

function _M:attach(id, attrs, touch)

    attrs = attrs or {}
    touch = lf.needTrue(touch)

    if lf.isObj(id) then
        if id:__is('model') then
            id = id:getKey()
        end

        if id:__is('col') then
            id = id:modelKeys()
        end
    end

    local query = self:newPivotStatement()

    local ids = lf.asTbl(id)

    query:inserts(self:createAttachRecords(ids, attrs))

    if touch then
        self:touchIfTouching()
    end
end

function _M.__:createAttachRecords(ids, attrs)

    local records = {}

    local timed = self:hasPivotColumn(self:createdAt()) or
        self:hasPivotColumn(self:updatedAt())
 
    for key, value in pairs(ids) do
        tapd(records, self:attacher(key, value, attrs, timed))
    end

    return records
end

function _M.__:attacher(key, value, attrs, timed)

    local id, extra = self:getAttachId(key, value, attrs)
 
    local record = self:createAttachRecord(id, timed)

    return tb.merge(record, extra)
end

function _M.__:getAttachId(key, value, attrs)

    if lf.isTbl(value) then
        return key, tb.merge(value, attrs)
    end

    return value, attrs
end

function _M.__:createAttachRecord(id, timed)

    local record = {}
    record[self.foreignKey] = self.parent:getKey()
    record[self.otherKey] = id

    if timed then
        record = self:setTimestampsOnAttach(record)
    end

    return record
end

function _M.__:setTimestampsOnAttach(record, exists)

    local fresh = self.parent:freshTimestamp()

    if not exists and self:hasPivotColumn(self:createdAt()) then
        record[self:createdAt()] = fresh
    end

    if self:hasPivotColumn(self:updatedAt()) then
        record[self:updatedAt()] = fresh
    end

    return record
end

function _M:detach(ids, touch)

    touch = lf.needTrue(touch)

    if lf.isObj(ids) and ids:__is('model') then
        ids = ids:getKey()
    end

    if lf.isObj(ids) and ids:__is('col') then
        ids = ids:modelKeys()
    end

    local query = self:newPivotQuery()
    
    ids = lf.needList(ids)

    if #ids > 0 then
        query:whereIn(self.otherKey, ids)
    end
    
    local results = query:delete()

    if touch then
        self:touchIfTouching()
    end

    return results
end

function _M:touchIfTouching()

    if self:touchingParent() then
        self:getParent():touch()
    end

    if self:getParent():touches(self.relationName) then
        self:touch()
    end
end

function _M.__:touchingParent()

    return self:getRelated():touches(self:guessInverseRelation())
end

function _M.__:guessInverseRelation()

    return str.camel(str.plural(self:getParent().__cls))
end

function _M.__:newPivotQuery()

    local query = self:newPivotStatement()

    for _, whereArgs in ipairs(self.pivotWheres) do
        query:where(unpack(whereArgs))
    end

    for _, whereArgs in ipairs(self.pivotWhereIns) do
        query:whereIn(unpack(whereArgs))
    end

    return query:where(self.foreignKey, '=', self.parent:getKey())
end

function _M:newPivotStatement()

    return self.query:getQuery():newQuery(self.table)
end

function _M:newPivotStatementForId(id)

    return self:newPivotQuery():where(self.otherKey, '=', id)
end

function _M:newPivot(attrs, exists)

    local pivot = self.related:newPivot(self.parent, attrs, self.table, exists)

    return pivot:setPivotKeys(self.foreignKey, self.otherKey)
end

function _M:newExistingPivot(attrs)

    return self:newPivot(attrs, true)
end

function _M:withPivot(...)

    local columns = lf.needArgs(...)

    self.pivotColumns = tb.merge(self.pivotColumns, columns)

    return self
end

function _M:withTimestamps(createdAt, updatedAt)

    self.pivotCreatedAt = createdAt
    self.pivotUpdatedAt = updatedAt

    return self:withPivot(self:createdAt(), self:updatedAt())
end

function _M:createdAt()

    return self.pivotCreatedAt or self.parent:getCreatedAtColumn()
end

function _M:updatedAt()

    return self.pivotUpdatedAt or self.parent:getUpdatedAtColumn()
end

function _M:getRelatedFreshUpdate()

    local t = {}
    t[self.related:getUpdatedAtColumn()] =  self.related:freshTimestampString()

    return t
end

function _M:getHasCompareKey()

    return self:getForeignKey()
end

function _M:getForeignKey()

    return self.table .. '.' .. self.foreignKey
end

function _M:getOtherKey()

    return self.table .. '.' .. self.otherKey
end

function _M:getTable()

    return self.table
end

function _M:getRelationName()

    return self.relationName
end

return _M

