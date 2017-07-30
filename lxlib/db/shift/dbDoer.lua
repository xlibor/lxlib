
local lx, _M, mt = oo{
    _cls_    = '',
    _bond_    = 'shiftDoerBond'
}

local app, lf, tb, str = lx.kit()

local dbInit = lx.db

function _M:new(table)

    local this = {
        table = table,
        db = app:get('db'),
    }

    oo(this, mt)

    return this
end

function _M:getRan()

    local query = self:query()

    return query:orderBy('batch', 'shift'):pluck('shift')
end

function _M.__:query()

    return self:getConn():table(self.table)
end

function _M:getShifts(steps)

    local q = self:query()

    q:where('batch', '>=', '1'):orderBy{'shift', 'desc'}:take(steps)

    return q:get()
end

function _M:getLast()

    local q = self:query()
    q:where('batch', '=', self:getLastBatchNumber())

    return q:orderBy{'shift', 'desc'}:get()
end

function _M:log(file, batch)

    self:query():set{shift = file, batch = batch}:insert()
end

function _M:delete(shift)

    self:query():where{shift = shift}:delete()
end

function _M:getNextBatchNumber()

    return self:getLastBatchNumber() + 1
end

function _M:getLastBatchNumber()

    return self:query():max('batch')
end

function _M:create()

    local schema = self:getSchema()
    schema:create(self.table, function(table)
        table:increments('id')
        table:string('shift')
        table:integer('batch')
    end)

end

function _M:isValid()
    
    local schema = self:getSchema()

    return schema:hasTable(self.table)
end

function _M:getConn()

    local connName = self.connName

    return self.db:conn(connName)
end

function _M.__:getSchema()

    local conn = self:getConn()
    local sb = conn:getSchemaBuilder()

    return sb
end

function _M:setSource(name)

    self.connName = name
end

return _M

