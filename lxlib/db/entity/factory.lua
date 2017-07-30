
local _M = {
    _cls_    = ''
}

local mt = { __index = _M }

local lx = require('lxlib')
local app = lx.app()

function _M:new(baseDbos)

    local this = {
        baseDbos = baseDbos
    }

    setmetatable(this, mt)
 
    this:makeDbos()
 
    return this
end

function _M:makeDbo(dboName, addTableName)

    local baseDbos = self.baseDbos
    local dbo

    if not baseDbos then
        dbo = app:make('db.dbo', dboName, addTableName)
    else
        local tblDef = baseDbos[dboName]
        local baseCols = self.dbosColumnsList[dboName]
        local baseColsWithTblName = self.dbosColumnsListWithTblName[dboName]
         
        dbo = {
            tblDef = tblDef,
            _columns = baseCols,
            _fullColumns = baseColsWithTblName,
            _tblName = dboName
         }

        dbo = app:make('db.dbo', dbo)

        local pk = self.dbosPrimaryKeyList[dboName]
        if pk then 
            dbo.primaryKey = pk
            local fDef = tblDef[pk]
            if fDef then
                dbo.pkDataType = fDef.dt
            end
        end
    end

    return dbo
end

function _M:makeDbos()

    local baseDbos = self.baseDbos

    if not baseDbos then
        self.dbos = app:make('db.dbos')
        return
    end

    local dbos, dbosColumnsList = {}, {}
    local dbosColumnsListWithTblName = {}
    local dbosPrimaryKeyList = {}
    local cbConf
    local isPrimaryKey, primaryKey
    local dboDef, columnName, tblColumns, tblColumnsWithTblName

    for k, v in pairs(baseDbos) do
        dbos[k] = k
        dboDef = v
        tblColumns = {}
        tblColumnsWithTblName = {}
        
        primaryKey = nil
        for colKey,colDef in pairs(dboDef) do
            columnName,isPrimaryKey = colDef.name, colDef.pri
            if columnName then
                tblColumns[colKey] = columnName
                tblColumnsWithTblName[colKey] = k .. '.' .. columnName
                if isPrimaryKey then primaryKey = columnName end
            else
                tblColumns[colKey] = colKey
                tblColumnsWithTblName[colKey] = k .. '.' .. colKey
                if isPrimaryKey then primaryKey = colKey end
            end
        end
        
        tblColumns._tblName = k
        tblColumnsWithTblName._tblName = k
        dbosColumnsList[k] = tblColumns
        dbosColumnsListWithTblName[k] = tblColumnsWithTblName
        if primaryKey then dbosPrimaryKeyList[k] = primaryKey end
    end

    self.dbos = dbos
    self.dbosColumnsList = dbosColumnsList
    self.tblColumnsWithTblName = tblColumnsWithTblName
    self.dbosColumnsListWithTblName = dbosColumnsListWithTblName
    self.dbosPrimaryKeyList = dbosPrimaryKeyList

    -- local appCbConf =  ormConf.callback
    -- if not appCbConf.usable then
    --     self.cbConf = {}
    -- else
    --     self.cbConf = appCbConf.list
    -- end
end

function _M:getDbos()

    return self.dbos
end

return _M

