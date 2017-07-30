
local lx, _M = oo{
    _cls_   = '',
    _ext_   = 'model'
}

local app, lf, tb, str = lx.kit()

function _M:ctor(parent, attrs, table, exists)

    if not parent then
        return
    end
    
    self.__skip = true
    self:__super(_M, 'ctor')

    self:rawset('foreignKey', false)
    self:rawset('otherKey', false)
    self.guarded = {}
    self:setTable(table)

    self:setConnection(parent:getConnName())

    self:forceFill(attrs)
    self:syncOriginal()
    self:rawset('parent', parent)
    self.exists = exists

    self.timestamps = self:hasTimestampAttrs()

end

function _M:fromRawAttrs(parent, attrs, table, exists)

    local instance = self:__new(parent, attrs, table, exists)

    instance:setRawAttrs(attrs, true)

    return instance
end

function _M:setKeysForSaveQuery(query)

    query:where(self.foreignKey, '=', self:getAttr(self.foreignKey))

    return query:where(self.otherKey, '=', self:getAttr(self.otherKey))
end

function _M:delete()

    return self:getDeleteQuery():delete()
end

function _M:getDeleteQuery()

    local foreign = self:getAttr(self.foreignKey)

    local query = self:newQuery():where(self.foreignKey, '=', foreign)

    return query:where(self.otherKey, '=', self:getAttr(self.otherKey))
end

function _M:getForeignKey()

    return self.foreignKey
end

function _M:getOtherKey()

    return self.otherKey
end

function _M:setPivotKeys(foreignKey, otherKey)

    self.foreignKey = foreignKey

    self.otherKey = otherKey

    return self
end

function _M:hasTimestampAttrs()

    return tb.exists(self.attrs, self:getCreatedAtColumn())
end

function _M:getCreatedAtColumn()

    return self.parent:getCreatedAtColumn()
end

function _M:getUpdatedAtColumn()

    return self.parent:getUpdatedAtColumn()
end

return _M


