
local lx, _M = oo{
    _cls_    = '',
}

local app, lf, tb, str = lx.kit()

local static

function _M._init_(this)

    static = this.static
end

function _M:ctor()

    self:rawset('forceDeleting', false)
end

function _M._fix_(this)

    app:fix(this, 'orm.query', 'lxlib.db.orm.softDeleteQuery')
    local bag = app:getClsBaseInfo('lxlib.db.orm.softDeleteQuery').bag
    for k, v in pairs(bag) do
        if lf.isFunc(v) and not _M[k] then
            this[k] = function(model, ...)
                local query = model:newQuery()

                local func = query[k]

                return func(query, ...)
            end
        end
    end
end

function _M:bootSoftDelete()

    self:addGlobalScope(app:make('lxlib.db.orm.softDeleteScope'))
end

function _M:forceDelete()

    self.forceDeleting = true
    local deleted = self:delete()
    self.forceDeleting = false
    
    return deleted
end

function _M.__:performDeleteOnModel()

    if self.forceDeleting then
        
        return self:newQueryWithoutScopes()
            :where(self:getKeyName(), self:getKey())
            :forceDelete()
    end
    
    return self:runSoftDelete()
end

function _M.__:runSoftDelete()

    local query = self:newQueryWithoutScopes()
        :where(self:getKeyName(), self:getKey())
    local time = self:freshTimestamp()
    self[self:getDeletedAtColumn()] = time
    query:update(
        {[self:getDeletedAtColumn()] = self:fromDateTime(time)}
    )
end

function _M:restore()

    if self:fireModelEvent('restoring') == false then
        
        return false
    end

    self[self:getDeletedAtColumn()] = ngx.null
    
    self.exists = true
    local result = self:save()
    self:fireModelEvent('restored', false)
    
    return result
end

function _M:trashed()

    return lf.notEmpty(self[self:getDeletedAtColumn()])
end

function _M:restoring(callback)

    static.registerModelEvent('restoring', callback)
end

function _M:restored(callback)

    static.registerModelEvent('restored', callback)
end

function _M:getDeletedAtColumn()

    local deleteAt = self:__static('deleteAt')
    return deleteAt or 'deleted_at'
end

function _M:getQualifiedDeletedAtColumn()

    return self:getTable() .. '.' .. self:getDeletedAtColumn()
end

return _M

