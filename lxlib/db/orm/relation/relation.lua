
local lx, _M, mt = oo{
    _cls_        = '',
    a__            = {},
    _static_     = {
        morphMap = {},
        constraints = true
    }
}

local app, lf, tb, str = lx.kit()

local static

function _M._init_(this)

    static = this.static
end

function _M:new(query, parent)

    local this = {
        query    = query,
        parent    = parent,
        related    = query:getModel()
    }

    oo(this, mt)

    return this
end

function _M:ctor()

    self:addConstraints()
end

function _M.a__:addConstraints() end

function _M.a__:addEagerConstraints(models) end

function _M.a__:initRelation(models, relation) end

function _M.a__:match(models, results, relation) end

function _M.a__:getResults() end

function _M:getEager()

    return self:get()
end

function _M:touch()

    local column = self:getRelated():getUpdatedAtColumn()
    local tbl = {[column] = self:getRelated():freshTimestampString()}

    self:rawUpdate(tbl)
end

function _M:rawUpdate(attrs)

    self.query:update(attrs)
end

function _M:getRelationCountQuery(query, parent)

    return self:getRelationQuery(query, parent, query:exp('count(*)'))
end

function _M:getRelationQuery(query, parent, ...)

    query:sel(...)

    local key = self:warp(self:getQualifiedParentKeyName())

    return query:where(self:getHasCompareKey(), '=', query:exp(key))
end

function _M.noConstraints(cb)

    local previous = static.constraints
    static.constraints = false

    local results = cb()

    static.constraints = previous

    return results
end

function _M:getKeys(models, key)

    return tb.unique(tb.values(tb.map(models, function(value)
        return key and value:getAttribute(key) or value:getKey()
    end)))

end

function _M:getQuery()

    return self.query
end

function _M:getBaseBuilder()

    return self.query:getBuilder()
end

function _M:getParent()

    return self.parent
end

function _M:getQualifiedParentKeyName()

    return self.parent:getQualifiedKeyName()
end

function _M:getRelated()

    return self.related
end

function _M:createdAt()

    return self.parent:getCreatedAtColumn()
end

function _M:updatedAt()

    return self.parent:getUpdatedAtColumn()
end

function _M:relatedUpdatedAt()

    return self.related:getUpdatedAtColumn()
end

function _M:warp(value)

    return value
end

function _M.morphMap(map, merge)
 
    merge = lf.needTrue(merge)

    map = _M.buildMorphMapFromModels(map)

    if lf.isTbl(map) then
        static.morphMap = merge and tb.merge(static.morphMap, map) or map
    end

    return static.morphMap
end

function _M.buildMorphMapFromModels(models)

    if not models then return models end
    if tb.isAssoc(models) then return models end

    local tables = tb.map(models, function(model)
        model = app:make(model)

        return model:getTable()
    end)

    return tb.combine(tables, models)
end    

function _M:_run_(method)

    return function(self, ...)
        local query = self.query
        local func
 
        func = query[method]
        local result = func(query, ...)
         
        if result == query then
            return self
        end

        return result
    end
end

function _M:_clone_(newObj)

    newObj.query = self.query:__clone()
end

return _M

