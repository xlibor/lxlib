
local lx, _M, mt = oo{
    _cls_   = '',
    _bond_  = 'scope'
}

local app, lf, tb, str = lx.kit()

function _M:apply(query, model)

    query:isNull(model:getQualifiedDeletedAtColumn())
end

function _M:extend(query)

    query:onDelete(function(query)
        local column = self:getDeletedAtColumn(query)
        
        return query:update({column = query:getModel():freshTimestampString()})
    end)
end

function _M.__:getDeletedAtColumn(query)

    if query:getBuilder():joinedCount() > 0 then
        
        return query:getModel():getQualifiedDeletedAtColumn()
    else 
        
        return query:getModel():getDeletedAtColumn()
    end
end
 
return _M

