
local lx, _M, mt = oo{
    _cls_   = '',
    _ext_   = 'orm.query'
}

local app, lf, tb, str = lx.kit()
local scope = 'softDeleteScope'

function _M:forceDelete()

    return self:getBuilder():delete()
end

function _M:restore()

    self:withTrashed()
    
    return self:update(
        {[self:getModel():getDeletedAtColumn()] = ngx.null}
    )

end

function _M:withTrashed()

    return self:withoutGlobalScope(scope)
end

function _M:withoutTrashed()

    model = self:getModel()
    self:withoutGlobalScope(scope):whereNull(
        model:getQualifiedDeletedAtColumn()
    )
    
    return self
end

function _M:onlyTrashed()

    model = self:getModel()
    self:withoutGlobalScope(scope):whereNotNull(
        model:getQualifiedDeletedAtColumn()
    )
    
    return self
end

return _M

