
local _M = {
    _cls_    = '',
    _ext_    = 'relation'
}

local mt = {__index = _M}

local lx = require('lxlib').load(_M)
local app, lf, tb, str = lx.kit()
local Relation = lx.use('relation')

local static

function _M._init_(this)

    static = this.static
end

function _M:ctor(query, parent, foreignKey, otherKey, relation)

    self.foreignKey = foreignKey
    self.otherKey = otherKey

    self.relation = relation
    self.__skip = true
    self:__super(_M, 'ctor', query, parent)
end

function _M:getResults()

    return self.query:first()
end

function _M:addConstraints()

    if static.constraints then

        local table = self.related:getTable()

        local value = self.parent:getAttr(self.foreignKey)

        self.query:where(table..'.'..self.otherKey, '=', value)
    end
end

function _M:getRelationQuery(query, parent, ...)
    
    if parent:baseTable() == query:baseTable() then
        return self:getRelationQueryForSelfRelation(query, parent, ...)
    end

    query:select(...)
    local otherKey = query:getModel():getTable() .. '.' .. self.otherKey

    return query:where(self:getQualifiedForeignKey(), '=', query.cf(otherKey))
end

function _M:getRelationQueryForSelfRelation(query, parent, ...)

    query:sel(...)

    local hash = self:getRelationCountHash()

    query:tableAs(hash)

    local key = self:warp(self:getQualifiedParentKeyName())

    return query:where(hash..'.'..self:getModel():getKeyName(), '=', query:exp(key))
end

function _M:getRelationCountHash()

    return 'self_' .. lf.guid()
end

function _M:addEagerConstraints(models)

    local key = self.related:getTable()..'.'..self.otherKey

    return self.query:where(key, 'in', self:getEagerModelKeys(models))
end

function _M:getEagerModelKeys(models)

    local keys = {}
    local foreignKey = self.foreignKey
    local value
    for _, model in ipairs(models) do
        value = model[foreignKey]
        if value then
            tapd(keys, value)
        end
    end

    if #keys == 0 then
        return {0}
    end

    return tb.values(tb.unique(keys))
end

function _M:initRelation(models, relation)

    for _, model in ipairs(models) do
        model:setRelation(relation)
    end

    return models
end

function _M:match(models, results, relation, matchType)

    local foreign, other = self.foreignKey, self.otherKey

    local dictionary = {}

    for _, result in ipairs(results) do
        dictionary[result:getAttr(other)] = result
    end

    local key, value
    for _, model in pairs(models) do
        key = model:getAttr(foreign)
        value = dictionary[key]
        if value then
            model:setRelation(relation, value)
        end
    end

    return models
end

function _M:associate(model)
    
    local isModel = lf.isObj(model)
    local otherKey = isModel and model:getAttr(self.otherKey) or model

    self.parent:setAttr(self.foreignKey, otherKey)

    if isModel then
        self.parent:setRelation(self.relation, model)
    end

    return self.parent
end

function _M:dissociate()

    self.parent:setAttr(self.foreignKey, nil)

    return self.parent:setRelation(self.relation, nil)
end


function _M:getRelationValue(dictionary, key, matchType)

    local value = dictionary[key]

    return matchType == 'one' and value[1] or value
end
 
function _M:update(attrs)

    local instace = self:getResults()

    return instace:fill(attrs):save()
end
 
function _M:getForeignKey()

    return self.foreignKey
end

function _M:getQualifiedForeignKey()

    return self.parent:getTable() .. '.' .. self.foreignKey
end

function _M:getOtherKey()

    return self.otherKey
end
 
function _M:getQualifiedOtherKeyName()

    return self.related:getTable() .. self.otherKey
end

return _M

