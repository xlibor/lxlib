
local lx, _M, mt = oo{
    _cls_ = '',
    _bond_ = 'verifierBond'
}

local app, lf, tb, str = lx.kit()

function _M:new(db)

    local this = {
        db = db,
        connection = nil
    }
    
    return oo(this, mt)
end

function _M:getCount(collection, column, value, excludeId, idColumn, extra)

    extra = extra or {}
    local query = self:table(collection):where(column, '=', value)
    if excludeId and excludeId ~= 'null' then
        query:where(idColumn or 'id', '<>', excludeId)
    end
    
    return self:addConditions(query, extra):count()
end

function _M:getMultiCount(collection, column, values, extra)

    extra = extra or {}
    local query = self:table(collection):whereIn(column, values)
    
    return self:addConditions(query, extra):count()
end

function _M.__:addConditions(query, conditions)

    for key, value in pairs(conditions) do
        if lf.isFun(value) then
            query:where(function(query)
                value(query)
            end)
        else 
            self:addWhere(query, key, value)
        end
    end
    
    return query
end

function _M.__:addWhere(query, key, extraValue)

    if extraValue == 'null' then
        query:whereNull(key)
    elseif extraValue == 'not_null' then
        query:whereNotNull(key)
    elseif str.startsWith(extraValue, '!') then
        query:where(key, '!=', str.substr(extraValue, 2))
    else 
        query:where(key, extraValue)
    end
end

function _M.__:table(table)

    return self.db:connection(self.connection):table(table):useWriteLdo()
end

function _M:setConnection(connection)

    self.connection = connection
end

return _M

