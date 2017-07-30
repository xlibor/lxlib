
local lx, _M = oo{
    _cls_   = '',
    _ext_   = 'belongsTo'
}

local app, lf, tb, str, new = lx.kit()

function _M:ctor(query, parent, foreignKey, otherKey, morphType, relation)

    self.morphType = morphType
    self.dictionary = {}
    self.macroBuffer = {}
    self:__super('ctor', query, parent, foreignKey, otherKey, relation)
    self.__skip = true
end

function _M:getResults()

    if not self.otherKey then
        return
    end

    return self.query:first()
end

function _M:addEagerConstraints(models)

    self.models = models
    self:buildDictionary(models)
end

function _M.__:buildDictionary(models)

    local t, key
    for _, model in ipairs(models) do
        t = rawget(model, self.morphType)
        if t then
            key = rawget(model, self.foreignKey)
            tb.mapd(self.dictionary, t, key, model)
        end
    end
end

function _M:match(models, results, relation)

    return models
end

function _M:associate(model)

    self.parent:setAttr(self.foreignKey, model:getKey())

    self.parent:setAttr(self.morphType, model:getMorphClass())

    return self.parent:setRelation(self.relation, model)
end

function _M:dissociate()

    self.parent:setAttr(self.foreignKey, nil)

    self.parent:setAttr(self.morphType, nil)

    return self.parent:setRelation(self.relation, nil)
end

function _M:getEager()

    local t = tb.keys(self.dictionary)
    for _, morphType in ipairs(t) do
        self:matchToMorphParents(morphType, self:getResultsByType(morphType))
    end

    return self.models
end

function _M.__:matchToMorphParents(morphType, results)

    local t
    for _, result in ipairs(results) do
        if self.dictionary[morphType][result:getKey()] then
            t = self.dictionary[morphType][result:getKey()]
            for _, model in ipairs(t) do
                model:setRelation(self.relation, result)
            end
        end
    end
end

function _M.__:getResultsByType(morphType)

    local instance = self:createModelByType(morphType)

    local key = instance:getTable()..'.'..instance:getKeyName()

    local query = self:replayMacros(instance:newQuery())
        :mergeModelDefinedRelationConstraints(self:getQuery())
        :with(self:getQuery():getEagerLoads())

    return query:whereIn(key, self:gatherKeysByType(morphType):all()):get()
end

function _M.__:gatherKeysByType(morphType)

    local foreign = self.foreignKey
    local t = lx.col(self.dictionary[morphType])

    t = tb.map(t, function(models)
        return rawget(models[1], foreign)
    end)
    t = tb.values(t)
    t = tb.unique(t)

    return t
end

function _M:createModelByType(morphType)

    class = self.parent:getActualClassNameForMorph(morphType)

    return new(class)
end

function _M:getMorphType()

    return self.morphType
end

function _M:getDictionary()

    return self.dictionary
end

function _M.__:replayMacros(query)

    for macro in ipairs(self.macroBuffer) do 
        lf.call({query, macro.method}, unpack(macro.parameters))
    end

    return query
end

function _M:_run_(method)
    echo('run:', method)
end

return _M

