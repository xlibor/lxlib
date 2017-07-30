
local ffi = require "ffi"

local sql3 = require "lxlib.db.driver.sqlite.base.sqlite3_ffi"

local sqlite = {}

--[[
DBConnection.__gc(self)
        if self.conn then
            self:Close()
        end
end
--]]
local DBConnection = {}
setmetatable(DBConnection, {
    __call = function(self, ...)
        return self:open(...)
    end,
})

local DBConnection_mt = {
    __index = DBConnection
}

function DBConnection:init(handle, dbname)
    local obj = {
        conn = handle,
        dbname = dbname,
    }
    setmetatable(obj, DBConnection_mt)

    return obj
end

function DBConnection:getNativeHandle()
    return self.conn
end

function DBConnection:open(dbname)
    dbname = dbname or ":memory:"

    local lpdb = ffi.new("sqlite3*[1]")
    local err = sql3.sqlite3_open(dbname, lpdb)

    if err ~= 0 then
        return false, err
    end

    return self:init(lpdb[0], dbname)
end

function DBConnection:close()
    local rc = sql3.sqlite3_close(self.conn)
    if rc == SQLITE_OK then
        self.conn = nil
    end

    return rc
end

function DBConnection:exec(statement, callbackfunc, userdata)
    --print("Exec: ", statement)
    local lperrMsg = ffi.new("char *[1]")
    local rc = sql3.sqlite3_exec(self.conn, statement, callbackfunc, userdata, lperrMsg)
    local errmsg = lperrMsg[0]

    if rc ~= SQLITE_OK then
        errmsg = ffi.string(errmsg)

        -- Free this to avoid a memory leak
        sql3.sqlite3_free(lperrMsg[0])

        return rc, errmsg
    else
        return rc, statement
    end
end

function DBConnection:getLastRowID()
    return tonumber(sql3.sqlite3_last_insert_rowid(self.conn))
end

function DBConnection:prepare(statement)
    return sqlite.DBStatement(self, statement)
end

function DBConnection:interrupt()
    return sql3.sqlite3_interrupt(self.conn)
end

-- DDL
function DBConnection:createTable(params)
    params.Connection = self
    return sqlite.DBTable:create(params)
end

function DBConnection:dropTable(tablename)
    local stmnt = string.format("DROP TABLE %s ", tablename)
    local rc, errmsg = self:exec(stmnt)

    if rc ~= SQLITE_OK then
        return nil, rc, errmsg
    else
        return true
    end
end

--[[
==============================================
        CRUD Operations with Tables
==============================================
--]]
DBTable = {}
setmetatable(DBTable, {
    __call = function(self, ...)
        return self:create(...)
    end,
})
DBTable_mt = {
    __index = DBTable
}


function DBTable:init(dbconn, tablename)
    local obj = {
        conn = dbconn,
        tablename = tablename,
    }
    setmetatable(obj, DBTable_mt)

    return obj
end


function DBTable:create(params)
    local tblName, columns = params.Name, params.Columns
    local stmnt
    if tblName then
        stmnt = string.format("CREATE TABLE %s (%s) ", tblName, columns)
    else
        local rawSql = params.Sql 

        local i,j = string.find(rawSql, '(%a+)')
        tblName = string.sub(rawSql, i,j)
        stmnt = 'CREATE TABLE ' .. rawSql
    end
 
    local rc, errmsg = params.Connection:exec(stmnt)

    if rc ~= SQLITE_OK then
        return nil, rc, errmsg
    end

    return self:init(params.Connection, tblName), stmnt
end

-- TODO: This should use the bind API, for safety.
function DBTable:insertValues(params)
    local stmnt
    if params.Columns then
        stmnt = string.format("INSERT INTO %s (%s) VALUES (%s)", self.tablename, params.Columns, params.Values)
    else
        stmnt = string.format("INSERT INTO %s VALUES (%s)", self.tablename, params.Values)
    end

    return self.conn:exec(stmnt)
end

function DBTable:delete(expr)
    if not expr then return 0 end

    local stmnt = string.format("DELETE FROM %s WHERE %s ", self.tablename, expr)

    return self.conn:exec(stmnt)
end

function DBTable:select(expr, columns)
    local stmnt

    if expr then
        stmnt = string.format("SELECT %s FROM %s", columns, self.tablename)
    else
        stmnt = string.format("SELECT %s FROM %s WHERE %s", columns, self.tablename, expr)
    end

    return self.conn:exec(stmnt)
end

--[[
int DBTable_column_metadata(
  sqlite3 *db,                /* Connection handle */
  const char *zDbName,        /* Database name or NULL */
  const char *zTableName,     /* Table name */
  const char *zColumnName,    /* Column name */
  char const **pzDataType,    /* OUTPUT: Declared data type */
  char const **pzCollSeq,     /* OUTPUT: Collation sequence name */
  int *pNotNull,              /* OUTPUT: True if NOT NULL constraint exists */
  int *pPrimaryKey,           /* OUTPUT: True if column part of PK */
  int *pAutoinc               /* OUTPUT: True if column is auto-increment */
)

        -- Handy CRUD operations



        Update = function(self, tablename, columns, values)
        end



        GetErrorMessage = function(self)
            return ffi.string(sql3.sqlite3_errmsg(self.conn))
        end
--]]

--[[
==============================================
        Statements
==============================================
--]]
local value_handlers = {
    [SQLITE_INTEGER] = function(stmt, n) return sql3.sqlite3_column_int(stmt, n) end,
    [SQLITE_FLOAT] = function(stmt, n) return sql3.sqlite3_column_double(stmt, n) end,
    [SQLITE_TEXT] = function(stmt, n) return ffi.string(sql3.sqlite3_column_text(stmt,n)) end,
    [SQLITE_BLOB] = function(stmt, n) return sql3.sqlite3_column_blob(stmt,n), sql3.sqlite3_column_bytes(stmt,n) end,
    [SQLITE_NULL] = function() return nil end
}

DBStatement = {}
setmetatable(DBStatement, {
    __call = function(self, ...)
        return self:create(...)
    end,
})
DBStatement_mt = {
    __index = DBStatement,
}

function DBStatement:init(dbconn, stmt)
    local obj = {
        conn = dbconn,
        stmt = stmt,
        bindCount = 0,
        PositionedOnRow = false,
    }
    setmetatable(obj, DBStatement_mt)

    return obj
end

function DBStatement:create(dbconn, statement)
    local ppStmt = ffi.new("sqlite3_stmt *[1]")
    local pzTail = ffi.new("const char *[1]")

    local rc = sql3.sqlite3_prepare_v2(dbconn:getNativeHandle(), statement, #statement+1, ppStmt, pzTail)

    if rc ~= SQLITE_OK then
        local errmsg =  ffi.string(sql3.sqlite3_errmsg(dbconn.conn))
        return false, errmsg
    end 

    return self:init(dbconn, ppStmt[0])
end

function DBStatement:bind(data, data_type)
    if type(data) == "table" then
        for _, bind in ipairs(data) do
            self:bind(bind[1], bind[2])
        end
        return
    end
    local binds = {
        -- blob     = function(s, i, v) sql3.sqlite3_bind_blob(s, i, v) end,
        double   = function(s, i, v) return sql3.sqlite3_bind_double(s, i, v) end,
        int      = function(s, i, v) return sql3.sqlite3_bind_int(s, i, v) end,
        int64    = function(s, i, v) return sql3.sqlite3_bind_int64(s, i, v) end,
        null     = function(s, i, v) return sql3.sqlite3_bind_null(s, i) end,
        text     = function(s, i, v) return sql3.sqlite3_bind_text(s, i, v or "", -1, nil) end,
        -- text16   = sql3.sqlite3_bind_text16,
        -- value    = sql3.sqlite3_bind_value,
        -- zeroblob = sql3.sqlite3_bind_zeroblob,
    }
    local type_map = {
        number  = "double",
        string  = "text",
        boolean = "int",
    }
    self.bindCount = self.bindCount + 1
    data_type = data_type or type_map[type(data)]
    assert(data_type)
    index = index
    local fn = binds[data_type]
    assert(fn)
    local rc = fn(self.stmt, self.bindCount, data)
    if rc ~= SQLITE_OK then
        console.e("[DB] %d", rc)
        return false, rc
    end
    return true
end

function DBStatement:getColumnName(n)
    return ffi.string(sql3.sqlite3_column_name(self.stmt, n-1))
end

function DBStatement:getColumnValue(n)
    return value_handlers[sql3.sqlite3_column_type(self.stmt,n-1)](self.stmt,n-1)
end

function DBStatement:getRowList()
    if not self.PositionedOnRow then return nil end

    local res = {}
    local row, columnName, value
    local nCols = self:dataRowColumnCount()
    for i=1,nCols do
        res[i] = self:getColumnValue(i)
    end
 
    return res, nCols
end

function DBStatement:getRowTable()
    if not self.PositionedOnRow then return nil end

    local res = {}
    local row, columnName, value
    local nCols = self:dataRowColumnCount()
    for i=1,nCols do
        res[self:getColumnName(i)] = self:getColumnValue(i)
    end
 
    return res, nCols
end

--[[
    This is an iterator
    It will call the step() function before
    returning rows as lua tables

    Usage:
    for row in stmt:results() do
        printRow(row)
    end
--]]

function DBStatement:rows(isNeedList)
    local rows = {}
     
    local rc = self:step()
    local i = 1
    local row 
    while rc == SQLITE_ROW do
        if not isNeedList then
            row = self:getRowTable()
        else
            row = self:getRowList()
        end
        if row then
            rows[i] = row
            rc = self:step()
            i = i + 1
        else
            break
        end
    end

    if rc == SQLITE_DONE then
        self:finish()
    end

    return rows
end

function DBStatement:results(isNeedList)
    -- Assume the statement has already been Prepared
    local closure = function()
        local rc = self:step()

        if rc ~= SQLITE_ROW then
            if rc == SQLITE_DONE then
                self:finish()
            end
            return nil
        end
        if not isNeedList then
            return self:getRowTable()
        else
            return self:getRowList()
        end
    end

    return closure
end

function DBStatement:run()
    local rc = self:step()
    self:finish()
    return rc == SQLITE_DONE, rc
end

function DBStatement:finish()
    if self.PositionedOnRow then
        local rc = sql3.sqlite3_finalize(self.stmt)
        self.PositionedOnRow = false
    end
end

function DBStatement:step()
    local rc = sql3.sqlite3_step(self.stmt)
    self.PositionedOnRow = rc == SQLITE_ROW

    return rc
end

function DBStatement:reset()
    local rc = sql3.sqlite3_reset(self.stmt)
    self.PositionedOnRow = false

    return rc
end

-- Some attributes of the statement
-- Get number of columns from the prepared statement
function DBStatement:preparedColumnCount()
    return sql3.sqlite3_column_count(self.stmt)
end

function DBStatement:dataRowColumnCount()
    return sql3.sqlite3_data_count(self.stmt)
end

function DBStatement:isBusy()
    local rc = sql3.sqlite3_busy(self.stmt)
    return rc ~= 0
end

function DBStatement:isReadOnly()
    local rc = sql3.DBStatement_readonly(self.stmt)
    return rc ~= 0
end

sqlite.DBConnection = DBConnection
sqlite.DBTable = DBTable
sqlite.DBStatement = DBStatement

return sqlite
