
local lx, _M = oo{
    _cls_    = '',
    _ext_    = 'relation'
}

local app, lf, tb, str, new = lx.kit()

local sfind = string.find

local static

function _M._init_(this)

    static = this.static
end

function _M:ctor(query, parent, foreignKey, localKey)

    self.foreignKey = foreignKey
    self.localKey = localKey

    self.__skip = true
    self:__super(_M, 'ctor', query, parent)
end

function _M:addConstraints()

    if static.constraints then
        self.query:where(self.foreignKey, '=', self:getParentKey())
        self.query:where(self.foreignKey, '<>', ngx.null)
    end
end

function _M:getRelationQuery(query, parent, ...)

    if parent:baseTable() == query:baseTable() then
        return self:getRelationQueryForSelfRelation(query, parent, ...)
    end

    return self:__super(_M, 'getRelationQuery', query, parent, ...)
end

function _M:getRelationQueryForSelfRelation(query, parent, ...)

    query:sel(...)

    local hash = self:getRelationCountHash()

    query:tableAs(hash)

    local key = query:exp(self:getQualifiedParentKeyName())

    return query:where(hash .. '.' .. self:getPlainForeignKey(), '=', key)
end

function _M:getRelationCountHash()

    return 'self_' .. lf.guid()
end

function _M:addEagerConstraints(models)

    return self.query:where(self.foreignKey, 'in', self:getKeys(models, self.localKey))
end

function _M:matchOne(models, results, relation)

    return self:matchOneOrMany(models, results, relation, 'one')
end

function _M:matchMany(models, results, relation)

    return self:matchOneOrMany(models, results, relation, 'many')
end

function _M:matchOneOrMany(models, results, relation, matchType)

    local dictionary = self:buildDictionary(results)

    local key, value
    for _, model in pairs(models) do
        key = model:getAttr(self.localKey)

        if dictionary[key] then
            value = self:getRelationValue(dictionary, key, matchType)
            model:setRelation(relation, value)
        end
    end

    return models
end

function _M:getRelationValue(dictionary, key, matchType)

    local value = dictionary[key]

    return matchType == 'one' and value[1] or value
end

function _M:buildDictionary(results)

    local dictionary = {}

    local foreign = self:getPlainForeignKey()

    local key, tbl
    for _, result in ipairs(results) do
        key = result[foreign]

        if not dictionary[key] then
            dictionary[key] = {}
        end
        tbl = dictionary[key]
        tapd(tbl, result)
    end

    return dictionary
end

function _M:save(model)

    model:setAttr(self:getPlainForeignKey(), self:getParentKey())

    return model:save() and model or false
end

function _M:saveMany(models)

    for _, model in ipairs(models) do
        self:save(model)
    end

    return models
end

function _M:findOrNew(id, ...)

    local instance = self:find(id, ...)

    if not instance then
        instance = self.related:newInstance()
        instance:setAttr(self:getPlainForeignKey(), self:getParentKey())
    end

    return instance
end

function _M:firstOrNew(attrs)

    local instance = self:where(attrs):first()

    if not instance then
        instance = self.related:newInstance(attrs)
        instance:setAttr(self:getPlainForeignKey(), self:getParentKey())
    end

    return instance
end

function _M:firstOrCreate(attrs)

    local instance = self:where(attrs):first()

    if not instance then
        instance = self:create(attrs)
    end

    return instance
end

function _M:updateOrCreate(attrs, values)

    local instance = self:firstOrNew(attrs)

    instance:fill(values)

    instance:save()

    return instance
end

function _M:create(attrs)

    local instance = self.related:newInstance(attrs)
    instance:setAttr(self:getPlainForeignKey(), self:getParentKey())

    instance:save()

    return instance
end

function _M:createMany(records)

    local instances = {}

    for _, record in ipairs(records) do
        tapd(instances, self:create(record))
    end

    return instances
end

function _M:update(attrs)

    if self.related:usesTimestamps() then
        attrs[self:relatedUpdatedAt()] = self.related:freshTimestampString()
    end

    return self.query:update(attrs)
end

function _M:getHasCompareKey()

    return self:getForeignKey()
end

function _M:getForeignKey()

    return self.foreignKey
end

function _M:getPlainForeignKey()

    local foreignKey = self.foreignKey

    if not sfind(foreignKey, '%.') then
        return foreignKey
    else
        local tbl = str.split(foreignKey, '.')
        return tbl[#tbl]
    end
end

function _M:getParentKey()

    return self.parent:getAttr(self.localKey)
end

function _M:getQualifiedParentKeyName()

    return self.parent:getTable() .. '.' .. self.localKey
end

return _M

