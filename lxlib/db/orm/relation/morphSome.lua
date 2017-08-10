
local lx, _M = oo{
    _cls_   = '',
    _ext_   = 'hasSome'
}

local app, lf, tb, str = lx.kit()

local static

function _M._init_(this)

    static = this.static
end

function _M:ctor(query, parent, morphType, id, localKey)

    self.morphType = morphType

    self.morphClass = parent:getMorphClass()
    self.__skip = true
    self:__super(_M, 'ctor', query, parent, id, localKey)

end

function _M:addConstraints()

    if static.constraints then
        self:__super(_M, 'addConstraints')

        self.query:where(self.morphType, '=', self.morphClass)
    end
end

function _M:getRelationQuery(query, parent, columns)

    query = self:__super(_M, 'getRelationQuery', query, parent, columns)

    return query:where(self.morphType, self.morphClass)
end

function _M:addEagerConstraints(models)

    self:__super(_M, 'addEagerConstraints', models)

    self.query:where(self.morphType, self.morphClass)
end

function _M:save(model)

    model:setAttr(self:getPlainMorphType(), self.morphClass)

    return self:__super(_M, 'save', model)
end

function _M:findOrNew(id, columns)

    local instance = self:find(id, columns)
    if not instance then
        instance = self.related:newInstance()

        self:setForeignAttrsForCreate(instance)
    end

    return instance
end

function _M:firstOrNew(attrs)

    local instance = self:where(attrs):first()
    if not instance then
        instance = self.related:newInstance(attrs)
 
        self:setForeignAttrsForCreate(instance)
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
 
    self:setForeignAttrsForCreate(instance)

    instance:save()

    return instance
end

function _M.__:setForeignAttrsForCreate(model)

    model:rawset(self:getPlainForeignKey(), self:getParentKey())
 
    model:rawset(self:getPlainMorphType(), self.morphClass)
end

function _M:getMorphType()

    return self.morphType
end

function _M:getPlainMorphType()

    return tb.last(str.split(self.morphType, '.'))
end

function _M:getMorphClass()

    return self.morphClass
end

return _M

