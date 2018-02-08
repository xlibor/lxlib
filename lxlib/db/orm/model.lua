
local lx, _M, mt = oo{
    _cls_        = '',
    _bond_        = {
        'arrable', 'jsonable', 'strable', 'fixable', 'packable'
    },
    _static_     = {
        booted              = {},
        globalScopes        = {},
        mutatorCache        = {},
        snakeAttrs          = true,
        unguarded           = false,
        timestamps          = true,
        dateFormat          = '%Y-%m-%d %H:%M:%S',
        manyMethods         = {'belongsToMany', 'morphToMany', 'morphedByMany'},
        createdAt           = 'created_at',
        updatedAt           = 'updated_at',
        queryMethods        = {
            'select', 'sel', 'pick', 'where', 'orWhere', 'or_', 'whereIn',
            'whereBetween', 'between', 'get', 'set', 'first', 'find', 'create',
            'orderBy', 'group', 'groupBy', 'take', 'insert', 'inserts',
            'limit', 'from', 'count', 'withCount', 'withGlobalScope',
            'withoutGlobalScope', 'withoutGlobalScopes', 'pure',
            'findOrFail', 'firstOrFail', 'firstOrNew', 'firstOrCreate',
            'updateOrCreate', 'findOrNew',
            'getSql', 'paginate', 'paging', 'simplePaginate',
            'truncate', 'has', 'doesntHave', 'whereHas', 'whereDoesntHave',
            'getConnection', 'getConn', 'pluck', 'distinct',
        }
    }
}

local app, lf, tb, str, new = lx.kit()
local use, try, throw = lx.kit2()

local ssub, smatch, sgsub = string.sub, string.match, string.gsub

local Relation = use 'relation'
local static

function _M._init_(this)

    static = this.static
    static.queryMethodsMap = tb.flip(static.queryMethods, true)
end

function _M:new(attrs)

    local this = {
        conn                = false,
        table               = false,
        primaryKey          = 'id',
        keyType             = 'int',
        perPage             = 15,
        incrementing        = true,
        timestamps          = static.timestamps,
        attrs               = {},
        original            = {},
        relations           = {},
        hidden              = {},
        visible             = {},
        appends             = {},
        fillable            = {},
        guarded             = {},
        dates               = {},
        dateFormat          = static.dateFormat,
        casts               = {},
        _touches            = {},
        observables         = {},
        _with               = {},
        morphClass          = '', 
        exists              = false,
        wasRecentlyCreated  = false,
        query               = false,
        ctorFinished        = false,
    }

    oo(this, mt)

    return this
end

-- @item string|bool    conn
-- @item string|bool    table
-- @item string         primaryKey
-- @item string         keyType
-- @item number         perPage
-- @item boolean        incrementing
-- @item boolean        timestamps
-- @item table          attrs
-- @item table          original
-- @item table          relations
-- @item table          hidden
-- @item table          visible
-- @item table          appends
-- @item table          fillable
-- @item table          guarded
-- @item table          dates
-- @item table          casts
-- @item table          _touches
-- @item table          observables
-- @item table          _with
-- @item string         morphClass
-- @item boolean        exists
-- @item boolean        wasRecentlyCreated
-- @item boolean        query
-- @item boolean        ctorFinished

function _M:ctor(attrs)

    self:bootIfNotBooted()
    self:syncOriginal()

    self.fillable       = tb.flip(self.fillable, true)
    self.guarded        = tb.flip(self.guarded, true)
    self.visible        = tb.flip(self.visible, true)
    self.hidden         = tb.flip(self.hidden, true)
    self.appends        = tb.flip(self.appends, true)
    self:fill(attrs)
    self.ctorFinished   = true
end

function _M:bootIfNotBooted()

    local cls = self.__cls

    if not static.booted[cls] then
        static.booted[cls] = true
        self:fireModelEvent('booting')
        self:boot()
        self:fireModelEvent('booted')
    end
end

function _M:boot()

    self:bootMixins()
end

function _M:bootMixins()
    
    local method, func

    for _, mixin in ipairs(self.__mixins) do

        method = 'boot' .. str.ucfirst(mixin.__name)

        func = mixin[method]
        if func then
            func(self)
        end
    end
end

function _M:toFix(nick)

    local t = self:__fixed(nick)

    return t or nick
end

function _M:getQualifiedKeyName()

    local table = self:getTable()
    local keyName = self:getKeyName()

    if table and keyName then

        return table .. '.' .. keyName
    end
end

function _M:newQueryWithoutScopes()

    local builder = self:newBaseBuilder()
    local query = self:newBaseQuery(builder)

    return query:setModel(self):with(self._with) 
end

function _M.t__.query(this)

    return new(this):newQuery()
end

-- get a new query for the model's table.
-- @return orm.query

function _M:newQuery()
 
    local query = self:newQueryWithoutScopes()
 
    for id, scope in pairs(self:getGlobalScopes()) do

        query:withGlobalScope(id, scope)
    end

    return query
end

function _M:newBaseQuery(builder)

    local query = app:make(
        self:toFix('orm.query'), builder
    )

    return query
end

function _M:newBaseBuilder()

    local db = app:get('db')
    local builder = db:table(self:getTable())

    return builder
end

function _M:_(key, value)

    if not value then 
        return self:getAttr(key)
    else
        self.attrs[key] = value
    end
end

function _M:clearBootedModels()

    static.booted = {}
    static.globalScopes = {}
end

function _M:addGlobalScope(scope, impl)

    local globalScopes = static.globalScopes
    local cls = self.__cls

    if lf.isStr(scope) and impl then
        tb.set(globalScopes, cls, scope, impl)

        return impl
    end

    if lf.isFun(scope) then
        tb.set(globalScopes, cls, lf.guid(), scope)

        return scope
    end

    if lf.isObj(scope) then

        if scope:__is 'scope' then
 
            tb.set(globalScopes, cls, scope.__nick, scope)

            return scope
        end
    end

    error('global scope must be an instance of Closure or Scope.')
end

function _M:hasGlobalScope(scope)

    return self:getGlobalScope(scope) and true or false
end

function _M:getGlobalScope(scope)

    local modelScopes = tb.get(static.globalScopes, self.__cls, {})

    if lf.isStr(scope) then
        return modelScopes[scope]
    end
end

function _M:getGlobalScopes()

    return tb.get(static.globalScopes, self.__cls) or {}
end

function _M:save(options)

    options = options or {}

    local query = self:newQueryWithoutScopes()
    local saved

    if self:fireModelEvent('saving') then
        
        return false
    end

    self:syncAttrs()

    if self.exists then
        saved = self:performUpdate(query)
    else
        saved = self:performInsert(query)
    end

    if saved then
        self:finishSave(options)
    end

    return saved
end

function _M.t__.all(this, ...)
 
    local instance = new(this)
 
    return instance:newQuery():get(...)
end

function _M:finishSave(options)

    options = options or {}
    self:fireModelEvent('saved')

    self:syncOriginal()
    if tb.get(options, 'touch', true) then
        self:touchOwners()
    end
end

function _M:touchOwners()

    local related

    for _, relation in pairs(self._touches) do
        self:__do(relation):touch()
        related = self(relation)
        if related:__is('self') then
            related:fireModelEvent('saved', false)
            related:touchOwners()
        elseif related:__is('col') then
            related:each(function(relation)
                relation:touchOwners()
            end)
        end
    end
end

function _M:touches(relation)

    return tb.inList(self._touches, relation)
end

function _M:syncAttrs()

    local attrs = self.attrs
    local t

    for k, v in pairs(attrs) do
        t = rawget(self, k)
        if t then
            attrs[k] = t
        end
    end
end

function _M:syncOriginal()

    self.original = tb.clone(self.attrs)

    return self
end

function _M:syncOriginalAttribute(attr)

    self.original[attr] = self.attrs[attr]
    
    return self
end

function _M:performUpdate(query)

    if self:fireModelEvent('updating') then
        
        return false
    end

    if self.timestamps then
        self:updateTimestamps()
    end

    local dirty = self:getDirty()

    if next(dirty) then

        self:setKeysForSave(query):set(dirty):update()
        self:fireModelEvent('updated')
    end

    return true
end

function _M:performInsert(query)

    if self:fireModelEvent('creating') then
        
        return false
    end

    if self.timestamps then
        self:updateTimestamps()
    end

    local attrs = self.attrs
    query:set(attrs)

    if self:getIncrementing() then
        self:insertAndSetId(query, attrs)
    else
        query:insert()
    end

    self.exists = true
    self.wasRecentlyCreated = true
    self:fireModelEvent('created')

    return true
end

function _M:insertAndSetId(query, attrs)

    local id = query:insertGetId(attrs)
    local keyName = self:getKeyName()

    self:setAttr(keyName, id)
end

function _M:delete()

    if not self:getKeyName() then
        lx.throw('exception', 'no primary key defined on model')
    end

    if self.exists then
        if self:fireModelEvent('deleting') then
            
            return false
        end

        self:touchOwners()
        self:performDeleteOnModel()
        self.exists = false
        self:fireModelEvent('deleted')

        return true
    end

    return false
end

function _M:performDeleteOnModel()

    self:setKeysForSave(self:newQueryWithoutScopes()):delete()
end

function _M:getDirty()

    local dirty = {}
    local attrs, original = self.attrs, self.original

    local t
    for k, v in pairs(attrs) do
        t = original[k]
 
        if not t then
            dirty[k] = v
        elseif v ~= t then
            dirty[k] = v
        end
    end

    return dirty
end

function _M:getTable()

    local table = self.table
    if table then

        return table
    else
        local name = self.__name
        rawset(self, 'table', str.snake(str.plural(name)))

        return self.table
    end
end

function _M:setTable(table)

    self.table = table

    return self
end

function _M:getKey()

    return self:getAttr(self:getKeyName())
end

function _M:getKeyName()

    return self.primaryKey
end

function _M:setKeyName(key)

    self.primaryKey = key

    return self
end

function _M:setKeysForSave(query)

    return query:where(self:getKeyName(), '=', self:getKeyForSave())
end

function _M:getKeyForSave()

    local keyName = self:getKeyName()
    local value = self.original[keyName]

    if value then
        return value
    else
        return self:getAttr(keyName)
    end
end

function _M:hasAttrGetter(key)

    local attrGetters = self.attrGetters
    if not attrGetters then return false end

    return attrGetters[key] and true or false
end

_M.hasGetMutator = _M.hasAttrGetter

function _M:hasAttrSetter(key)

    local attrSetters = self.attrSetters
    if not attrSetters then return false end

    return attrSetters[key] and true or false
end

function _M:hasCast(key, types)

    local casts = self:getCasts()

    if casts[key] then
        if not types then
            return true
        else
            local castType = self:getCastType(key)
            local vt = type(types)
            if vt == 'string' then
                return castType == types and true or false
            elseif vt == 'table' then
                for _, v in ipairs(types) do
                    if castType == v then return true end
                end

                return false
            end
        end
    else
        return false
    end
end

function _M:getCastType(key)

    local casts = self:getCasts()

    return casts[key]
end

function _M:getCasts()

    return self.casts
end

function _M:getAttribute(key)

    if self.attrs[key] or self:hasAttrGetter(key) then
        return self:getAttrValue(key)
    end

    return self:getRelationValue(key)
end

_M.getAttr = _M.getAttribute

function _M:getAttrValue(key)

    local value = self.attrs[key]

    if self:hasAttrGetter(key) then

        return self:useAttrGetter(key, value)
    end
 
    if self:hasCast(key) then
        return self:castAttr(key, value)
    end

    return value
end

function _M:incrAttr(attrName, count)

    count = count or 1
    local attrValue = self.attrs[attrName] or 0
    self.attrs[attrName] = attrValue + count
end

function _M:decrAttr(attrName, count)

    count = count or 1
    local attrValue = self.attrs[attrName] or 0
    self.attrs[attrName] = attrValue - count
end

function _M:getAttributes()

    return self.attrs
end

_M.getAttrs = _M.getAttributes

function _M:castAttr(key, value)

    local castType = self:getCastType(key)

    if castType == 'int' or castType == 'integer' then
        return tonumber(value) or 0
    elseif castType == 'string' then
        return tostring(value)
    elseif castType == 'bool' or castType == 'boolean' then
        return value and true or false

    else
        return value
    end
end


function _M:useAttrGetter(key, value)

    key = self.attrGetters[key]
    local getter = self[key]

    return getter(self, value)
end

function _M:useAttrSetter(key, value)

    key = self.attrSetters[key]
    local setter = self[key]

    setter(self, value)
end

function _M:setAttr(key, value)

    if self:hasAttrSetter(key) then
        return self:useAttrSetter(key, value)
    end

    self.attrs[key] = value
 
    return self
end

_M.setAttribute = _M.setAttr

function _M:getIncrementing()

    return self.incrementing
end

function _M:setIncrementing(value)

    self.incrementing = value 

    return self
end

function _M:updateTimestamps()

    local ts = self:freshTimestamp()

    if not self:isDirty(static.updatedAt) then
        self:setUpdatedAt(ts)
    end

    if not (self.exists or self:isDirty(static.createdAt)) then
        self:setCreatedAt(ts)
    end
end

function _M:fromDateTime(value)

    return value

    -- local format = self:getDateFormat()
    -- value = self:asDateTime(value)
    
    -- return value:format(format)
end

function _M:useTimestamps()

    return self.timestamps
end

function _M.s__.defaultTimestamps(value)

    value = lf.needTrue(value)
    static.timestamps = value
end

function _M:setCreatedAt(value)

    self:setAttr(static.createdAt, value)
    
    return self
end

function _M:setUpdatedAt(value)

    self:setAttr(static.updatedAt, value)

    return self
end

function _M:getCreatedAtColumn()

    return static.createdAt
end

function _M:getUpdatedAtColumn()
    
    return static.updatedAt
end

function _M:freshTimestamp()

    local ts = lf.datetime()

    return ts
end

function _M:freshTimestampString()

    return self:fromDateTime(self:freshTimestamp())
end

function _M:getDates()

    local defaults = {static.createdAt, static.updatedAt}

    return self.timestamps and tb.merge(self.dates, defaults) or self.dates
end

function _M:isDirty(...)

    local attrs = lf.needArgs(...)
    local dirty = self:getDirty()
    if #attrs == 0 then
        return next(dirty) and true or false
    end

    for k, v in ipairs(attrs) do
        if dirty[v] then 
            return true
        end
    end

    return false
end

function _M:increment(column, amount, extra)

    amount = amount or 1
    
    return self:incrementOrDecrement(column, amount, extra, 'increment')
end

function _M:decrement(column, amount, extra)

    amount = amount or 1
    
    return self:incrementOrDecrement(column, amount, extra, 'decrement')
end

function _M.__:incrementOrDecrement(column, amount, extra, method)

    local query = self:newQuery()
    if not self.exists then
        return query:__do(method, column, amount, extra)
    end
    self:changeAttrValueValue(column, amount, method)

    return query:where(self:getKeyName(), self:getKey())
        :__do(method, column, amount, extra)
end

function _M:update(attrs, options)

    options = options or {}
    attrs = attrs or {}
    if not self.exists then
        
        return false
    end
    
    return self:fill(attrs):save(options)
end

function _M:touch()

    if not self.timestamps then
        
        return false
    end
    self:updateTimestamps()
    
    return self:save()
end

function _M.__:changeAttrValueValue(column, amount, method)

    if not static.queryMethodsMap[column] then
        self[column] = self[column] + (method == 'increment' and amount or amount * -1)
    end
    self:syncOriginalAttribute(column)
end

function _M:getRelationValue(key)

    if self:relationLoaded(key) then

        return self.relations[key]
    end

    if self:__has(key) then
        return self:getRelationshipFromMethod(key)
    end
end

function _M:getRelationshipFromMethod(method)

    local relations = lf.call{self, method}

    if not relations:__is(Relation) then
        error('relationship method must return an object of type relation')
    end

    local results = relations:getResults()

    self.relations[method] = results

    return results
end

function _M:newFromBuilder(attrs, conn)

    local model = self:newInstance({}, true)

    model:setRawAttrs(attrs, true)
    model:setConnName(conn or self.conn)

    return model
end

function _M:hydrate(items, conn)

    local instance = self:__new():setConnName(conn)

    items = tb.map(items, function(item)

        return instance:newFromBuilder(item)
    end)

    return items
end

function _M.t__.with(this, ...)

    local relations = lf.needArgs(...)

    local instance = new(this)

    return instance:newQuery():with(relations)
end

function _M:load(...)

    local relations = lf.needArgs(...)

    local query = self:newQuery():with(relations)

    query:eagerLoadRelations{self}

    return self
end

function _M:setRawAttrs(attrs, sync)

    self.attrs = attrs

    if sync then
        self:syncOriginal()
    end

    return self
end

function _M:rawset(key, value)

    rawset(self, key, value)
end

function _M:newInstance(attrs, exists)

    exists = lf.toBool(exists)
    local model = self:__new(attrs)
    model.exists = exists

    return model
end

function _M:setConnection(name)

    self.conn = name

    return self
end

_M.setConnName = _M.setConnection

function _M:getConnectionName()

    return self.conn
end

_M.getConnName = _M.getConnectionName

function _M:getForeignKey()

    return str.snake(self.__name) .. '_id'
end

function _M:getFillable()

    return self.fillable
end

function _M:setFillabel(fillable)

    self.fillable = fillable

    return self
end

function _M:getGuarded()

    return self.guarded
end

function _M:guard(guarded)

    self.guarded = tb.flip(guarded, true)

    return self
end

function _M.s__.unguard(state)

    state = lf.needTrue(state)

    static.unguarded = state
end

function _M.s__.reguard()

    static.unguarded = false
end

function _M.s__.isUnguarded()

    return static.unguarded
end

function _M.s__.unguardOn(cb)

    if static.unguarded then
        return cb()
    end

    static.unguard()

    local result = cb()

    static.reguard()

    return result
end

function _M:isFillable(key)

    if static.unguarded then
        return true
    end

    local fillable = self:getFillable()
    if fillable[key] then
        return true
    end

    if self:isGuarded(key) then
        return false
    end

    if tb.isEmpty(fillable) then
        return true
    end

    return true
end

function _M:isGuarded(key)

    local guarded = self:getGuarded()

    if guarded[key] or tb.just(guarded, '*') then
        return true
    end
end

function _M:totallyGuarded()

    if tb.isEmpty(self:getFillable()) and tb.just(self:getGuarded(), '*') then

        return true
    end
end

function _M:fill(attrs)

    if tb.isEmpty(attrs) then return self end

    local totallyGuarded = self:totallyGuarded()
    local fillable = self:fillableFromArray(attrs)

    for k, v in pairs(fillable) do
        k = str.last(k, '.')

        if self:isFillable(k) then
            self:setAttr(k, v)
        elseif totallyGuarded then
            error('massAssignmentException')
        end
    end

    return self
end

function _M:forceFill(attrs)

    local model = self

    return static.unguardOn(function()
        return model:fill(attrs)
    end)
end

function _M:fillableFromArray(attrs)

    local fillable = self:getFillable()

    if not tb.isEmpty(fillable) and not static.unguarded then
        return tb.cross(attrs, fillable)
    end

    return attrs
end

function _M:newPivot(parent, attrs, table, exists)

    return app:make('pivot', parent, attrs, table, exists)
end

function _M:relationLoaded(key)

    return self.relations[key] and true or false
end

function _M:getRelations()

    return self.relations
end

function _M:getRelation(relation)

    return self.relations[relation]
end

function _M:setRelation(relation, value)

    self.relations[relation] = value

    return self
end

function _M:setRelations(relations)

    self.relations = relations

    return self
end

function _M:hasOne(related, foreignKey, localKey)

    related = self:normalize(related)

    foreignKey = foreignKey or self:getForeignKey()
    local instance = new(related)

    localKey = localKey or self:getKeyName()

    return new('hasOne', instance:newQuery(), self,
        instance:getTable() .. '.' .. foreignKey, localKey)
end

function _M:morphOne(related, name, morphType, id, localKey)

    related = self:normalize(related)

    local instance = new(related)

    morphType, id = self:getMorphs(name, morphType, id)

    local table = instance:getTable()

    localKey = localKey or self:getKeyName()

    return new('morphOne',
        instance:newQuery(), self, table .. '.' .. morphType,
        table .. '.' .. id, localKey
    )
end

function _M:morphMany(related, name, morphType, id, localKey)

    related = self:normalize(related)

    local instance = new(related)

    morphType, id = self:getMorphs(name, morphType, id)

    local table = instance:getTable()

    localKey = localKey or self:getKeyName()

    return new('morphMany',
        instance:newQuery(), self, table .. '.' .. morphType,
        table .. '.' .. id, localKey
    )
end

function _M:morphToMany(related, name, table, foreignKey, otherKey, inverse)

    related = self:normalize(related)
    
    local caller = self.__name

    foreignKey = foreignKey or name..'_id'

    local instance = new(related)

    otherKey = otherKey or instance:getForeignKey()

    local query = instance:newQuery()

    table = table or str.plural(name)

    return new('morphToMany',
        query, self, name, table, foreignKey,
        otherKey, caller, inverse
    )
end

function _M:morphedByMany(related, name, table, foreignKey, otherKey)

    foreignKey = foreignKey or self:getForeignKey()

    otherKey = otherKey or name..'_id'

    return self:morphToMany(related, name, table, foreignKey, otherKey, true)
end

function _M:morphTo(name, morphType, id)

    if not name then

        name = str.snake(self.__name)
    end

    morphType, id = self:getMorphs(name, morphType, id)

    local class = self:getAttr(morphType)

    if not class then
        return new('morphTo',
            self:newQuery():setEagerLoads({}), self, id, nil, morphType, name
        )
    else 
        class = self:getActualClassNameForMorph(class)

        local instance = new(class)

        return new('morphTo',
            instance:newQuery(), self, id, instance:getKeyName(), morphType, name
        )
    end
end

function _M.__:getMorphs(name, morphType, id)

    morphType = morphType or name..'_type'

    id = id or name..'_id'

    return morphType, id
end

function _M:getMorphClass()

    local morphMap = Relation.morphMap()

    local class = self.__name

    if morphMap and tb.contains(morphMap, class) then
        return tb.search(morphMap, class, true)
    end

    return class
end

function _M:getActualClassNameForMorph(class)

    return tb.get(Relation.morphMap(), class, class)
end

function _M:hasMany(related, foreignKey, localKey)

    related = self:normalize(related)

    foreignKey = foreignKey or self:getForeignKey()
    local instance = new(related)
    localKey = localKey or self:getKeyName()

    local query = instance:newQuery()

    return new('hasMany', query, self,
        instance:getTable() .. '.' .. foreignKey, localKey)
end

function _M:belongsTo(related, foreignKey, otherKey, relation)

    related = self:normalize(related)

    local instance = new(related)

    if not relation then
        relation = instance.__name
    end

    if not foreignKey then
        foreignKey = str.snake(relation) .. '_id'
    end

    local query = instance:newQuery()

    otherKey = otherKey or instance:getKeyName()

    return new('belongsTo', query, self, foreignKey, otherKey, relation)
end

function _M:belongsToMany(related, table, foreignKey, otherKey, relation)

    related = self:normalize(related)

    local instance = new(related)

    if not relation then
        relation = instance.__name
    end

    foreignKey = foreignKey or self:getForeignKey()

    otherKey = otherKey or instance:getForeignKey()

    if not table then
        if type(related) == 'table' then
            related = related.__name
        end
        table = self:joiningTable(related)
    end

    local query = instance:newQuery()

    return new('belongsToMany', query, self, table, foreignKey, otherKey, relation)
end

function _M:joiningTable(related)

    local base = str.snake(self.__name)

    related = str.snake(lf.clsBase(related))

    local models = {related, base}

    tb.sort(models)

    return str.lower(str.join(models, '_'))
end

function _M:getBelongsToManyCaller()

end

function _M:getHidden()

    return self.hidden
end

function _M:setHidden(hidden)

    self.hidden = hidden

    return self
end

function _M:getPerPage()

    return self.perPage
end

function _M:setPerPage(perPage)

    self.perPage = perPage
    
    return self
end

function _M:addHidden(...)

    local attrs = lf.needArgs(...)

    self.hidden = tb.merge(self.hidden, attrs)
end

function _M:makeVisible(attrs)

    attrs = lf.asTbl(attrs)

    self.hidden = tb.diff(self.hidden, attrs)

    return self
end

function _M:getVisible()

    return self.visible
end

function _M:setVisible(visible)

    self.visible = visible

    return self
end

function _M:addVisible(...)

    local attrs = lf.needArgs(...)

    self.visible = tb.merge(self.visible, attrs)
end

function _M:toArr()

    local attrs = self:attrsToArr()
    local relations = self:relationsToArr()
    attrs = tb.merge(attrs, relations)

    return attrs
end

function _M:attrsToArr()

    local attrs = self:getArrableAttrs()

    local getters = self.attrGetters
    local key, value
    for key, _ in pairs(getters) do
        value = attrs[key]
        if value then
            attrs[key] = self:useAttrGetterForTbl(key, value)
        end
    end

    local casts = self:getCasts()
    for key, value in pairs(casts) do
        if attrs[key] and not getters[key] then
            attrs[key] = self:castAttr(key, attrs[key])
        end
    end

    for key, _ in pairs(self:getArrableAppends()) do
        attrs[key] = self:useAttrGetterForTbl(key, nil)
    end

    return attrs
end

function _M:useAttrGetterForTbl(key, value)

    local value = self:useAttrGetter(key, value)

    return value
end

function _M:relationsToArr()

    local key
    local relation
    local attrs = {}

    for key, value in pairs(self:getArrableRelations()) do
        
        if lf.isA(value, 'arrable') then
            relation = value:toArr()
        elseif not value then
            relation = value
        end
        
        if static.snakeAttrs then
            key = str.snake(key)
        end
        
        if relation or not value then
            attrs[key] = relation
        end

        relation = nil
    end
    
    return attrs
end

function _M.__:getArrableRelations()

    return self:getArrableItems(self.relations)
end

function _M:getArrableAttrs()

    return self:getArrableItems(self.attrs)
end

function _M:getArrableItems(values)

    local visible = self:getVisible()
    if not tb.isEmpty(visible) then
        return tb.cross(values, visible)
    end

    return tb.diffKey(values, self:getHidden())
end

function _M:getArrableAppends()
    
    local appends = self.appends

    if tb.isEmpty(appends) then return {} end

    return self:getArrableItems(appends)
end

function _M.__:fireModelEvent(event)

    return app:fire(self, event)
end

function _M.t__.regModelEvent(this, event, callback)

    local class = this.__cls

    app:listen(class .. '@' .. event, callback)
end

function _M.t__.created(this, callback)

    this:regModelEvent('created')
end

function _M.t__.creating(this, callback)

    this:regModelEvent('creating')
end

function _M.t__.updated(this, callback)

    this:regModelEvent('updated')
end

function _M.t__.updating(this, callback)

    this:regModelEvent('updating')
end

function _M.t__.deleted(this, callback)

    this:regModelEvent('deleted')
end

function _M.t__.deleting(this, callback)

    this:regModelEvent('deleting')
end

function _M:normalize(var)

    return lf.needCls(var)
end

function _M:getRouteKey()

    return self:getAttribute(self:getRouteKeyName())
end

function _M:getRouteKeyName()

    return self:getKeyName()
end

function _M:toJson()

    return lx.json.encode(self:toArr())
end

function _M:toStr()

    return self:toJson()
end

function _M:pack()

    local packed = {
        attrs       = self.attrs,
        relations   = self:packRelations(self.relations)
    }

    return packed, {attrs}
end

function _M.__:packRelations()

    local ret = {}
    local name
    for k, v in pairs(self.relations) do
        name = v.__cls
        if name then
            ret[k] = {
                name = name,
                attrs = v.attrs,
            }
        end
    end

    return ret
end

function _M:unpack(data)

    self:setRawAttrs(data.attrs, true)
    self:fill(attrs)
    self.exists = true
    
    local relations = {}
    local model
    for k, v in pairs(data.relations) do
        model = app:make(v.name, v.attrs)
        relations[k] = model
    end

    self.relations = relations
end

local function makeScope(baseMt, scope, primary)

    baseMt[scope] = function(self, ...)
        local query = self:newQuery()
        local func = baseMt[primary]

        local ret = func(self, query, ...) or query

        return ret
    end
end

function _M._load_(cls)

    local bag = cls.bag

    local baseMt = cls.baseMt
    local stackInfo = cls.stack
    local scope, field
    local mutator

    baseMt.attrGetters = {}
    baseMt.attrSetters = {}

    local needScopes = {}

    for k, v in pairs(baseMt) do
        if type(v) == 'function' then
            if str.startWith(k, 'scope') then
                scope = ssub(k, 6)
                scope = str.lcfirst(scope)
                needScopes[scope] = k
            elseif str.endWith(k, 'Attr') then
                field = smatch(k, 'get(%w+)Attr')
                if field then
                    field = str.lcfirst(field)
                    baseMt.attrGetters[field] = k
                end

                field = smatch(k, 'set(%w+)Attr')
                if field then
                    field = str.lcfirst(field)
                    baseMt.attrSetters[field] = k
                end
            end
        end
    end

    for scope, k in pairs(needScopes) do
        makeScope(baseMt, scope, k)
    end

    local queryMethods = static.queryMethods

    for _, method in ipairs(queryMethods) do
        if not baseMt[method] then
            baseMt[method] = function(self, ...)
                local query = self:newQuery()
                local func = query[method]

                return func(query, ...)
            end

            stackInfo[method] = function(this, ...)
 
                local instance = new(this)
                local query = instance:newQuery()
                local func = query[method]

                return func(query, ...)
            end
        end
    end

end

function _M:_get_(key)

    return self:getAttr(key)
end

function _M:_set_(key, value)

    if self.ctorFinished then
        self:setAttr(key, value)
    else
        rawset(self, key, value)
    end
end

function _M:__call(...)

    return self:getAttr(...)
end

return _M

