
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

function _M:new(table, column)

    local this = {
        table = table,
        column = column or 'null',
        ignore = nil,
        idColumn = 'id',
        wheres = {},
        _using = nil
    }
    
    return oo(this, mt)
end

function _M:where(column, value)

    if lf.isFun(column) then
        
        return self:using(column)
    end
    
    tapd(self.wheres, {column = column, value = value})
    
    return self
end

function _M:whereNot(column, value)

    return self:where(column, '!' .. value)
end

function _M:whereNull(column)

    return self:where(column, 'null')
end

function _M:whereNotNull(column)

    return self:where(column, 'not_null')
end

function _M:ignore(id, idColumn)

    idColumn = idColumn or 'id'
    self.ignore = id
    self.idColumn = idColumn
    
    return self
end

function _M:using(callback)

    self._using = callback
    
    return self
end

function _M.__:formatWheres()

    return Col(self.wheres):map(function(where)
        
        return where['column'] .. ',' .. where['value']
    end):join(',')
end

function _M:queryCallbacks()

    return self._using and {self._using} or {}
end

function _M:toStr()

    return str.rtrim(fmt('unique:%s,%s,%s,%s,%s',
        self.table, self.column,
        self.ignore and '"' .. self.ignore .. '"' or 'NULL',
        self.idColumn, self:formatWheres()), ','
    )
end

return _M

