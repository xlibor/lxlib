
local lx, _M, mt = oo{
    _cls_    = ''
}

local app, lf, tb, str = lx.kit()

local dbInit = lx.db

function _M:new(conn)

    local this = {
        conn = conn
    }

    oo(this, mt)

    return this
end

function _M:ctor()

end

function _M:create(table, callback)

    local ct = dbInit.sqlCreateTable(table)

    callback(ct.fields)

    self:build(ct)
end

function _M:table(table, callback)

    local ct = dbInit.sqlAlterTable(table)

    callback(ct.fields)

    self:build(ct)
end

_M.alter = _M.table

function _M:hasTable(table)

    local conn, dbType, dbName = self:getConn()
    local te = dbInit.sqlTableExists(table, dbName)
    local sql = te:sql(dbType)

    local rs = conn:exec(sql)

    return rs and #rs > 0
end

function _M:hasColumn(table, column)
 
    local columns = self:getColumns(table)

    for _, item in ipairs(columns) do
        if item.column_name == column then
            return true
        end
    end

    return false
end

function _M:hasColumns(table, columns)

    local tableColumns = tb.pluck(self:getColumns(table), 'column_name', 'column_name')

    for _, column in ipairs(columns) do
        if not tableColumns[column] then
            return false
        end
    end

    return true
end

function _M:getColumns(table, needAllInfo)

    local conn, dbType, dbName = self:getConn()
    local lc = dbInit.sqlLoadColumns(table, dbName)
    local sql = lc:sql(dbType, needAllInfo)

    local columns = conn:exec(sql)

    return columns or {}
end

function _M:drop(table)

    local conn, dbType, dbName = self:getConn()
    local dt = dbInit.sqlDropTable(table)
    local sql = dt:sql(dbType)

    return conn:exec(sql)
end

function _M:dropIfExists(table)

    local conn, dbType, dbName = self:getConn()
    local dt = dbInit.sqlDropTable(table, true)
    local sql = dt:sql(dbType)

    return conn:exec(sql)
end

function _M:rename(tableFrom, tableTo)

    local conn, dbType, dbName = self:getConn()
    local dt = dbInit.sqlRenameTable(tableFrom, tableTo)
    local sql = dt:sql(dbType)

    return conn:exec(sql)
end

function _M:enableForeignKeyConstraints()

end

function _M.__:build(sqlable)

    local conn, dbType = self:getConn()

    local sql = sqlable:sql(dbType)

    conn:exec(sql)
end

function _M.__:getConn()

    local conn = self.conn

    return conn, conn:getDbType(), conn:getDbName()
end

return _M

