
local lx, _M = oo{
    _cls_   = '',
    _ext_   = 'pivot'
}

local app, lf, tb, str = lx.kit()
 
function _M:setKeysForSaveQuery(query)

    query:where(self.morphType, self.morphClass)

    return self:__super(_M, 'setKeysForSaveQuery', query)
end

function _M:delete()

    query = self:getDeleteQuery()

    query:where(self.morphType, self.morphClass)

    return query:delete()
end


function _M:setMorphType(morphType)

    self.morphType = morphType

    return self
end

function _M:setMorphClass(morphClass)

    self.morphClass = morphClass

    return self
end

return _M

