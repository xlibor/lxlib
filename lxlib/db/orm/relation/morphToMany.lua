
local lx, _M = oo{
    _cls_   = '',
    _ext_   = 'belongsToMany'
}

local app, lf, tb, str, new = lx.kit()

function _M:ctor(query, parent, name, table, foreignKey, otherKey, relationName, inverse)

    self.inverse = inverse
    self.morphType = name..'_type'
    self.morphClass = inverse and query:getModel():getMorphClass()
        or parent:getMorphClass()

    self.__skip = true
    self:__super(_M, 'ctor', query, parent, table, foreignKey, otherKey, relationName)
end

function _M.__:setWhere()

    self:__super(_M, 'setWhere')

    self.query:where(self.table..'.'..self.morphType, '=', self.morphClass)

    return self
end

function _M:getRelationQuery(query, parent, columns)

    query = self:__super(_M, 'getRelationQuery', query, parent, columns)

    return query:where(self.table..'.'..self.morphType, '=', self.morphClass)
end

function _M:addEagerConstraints(models)

    self:__super(_M, 'addEagerConstraints', models)

    self.query:where(self.table..'.'..self.morphType, '=', self.morphClass)
end

function _M.__:createAttachRecord(id, timed)

    local record = self:__super(_M, 'createAttachRecord', id, timed)

    return tb.add(record, self.morphType, self.morphClass)
end

function _M.__:newPivotQuery()

    local query = self:__super(_M, 'newPivotQuery')

    return query:where(self.morphType, '=', self.morphClass)
end

function _M:newPivot(attrs, exists)

    attrs = attrs or {}
    local pivot = new('morphPivot', self.parent, attrs, self.table, exists)

    pivot:setPivotKeys(self.foreignKey, self.otherKey)
        :setMorphType(self.morphType)
        :setMorphClass(self.morphClass)

    return pivot
end

function _M:getMorphType()

    return self.morphType
end

function _M:getMorphClass()

    return self.morphClass
end

return _M

