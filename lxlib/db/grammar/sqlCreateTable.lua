
local _M = {
    _cls_ = '@sqlCreateTable'
}
local mt = { __index = _M }

local lx = require('lxlib')
local app, lf, tb, str = lx.kit()
local dbInit = lx.db
local pub = require('lxlib.db.pub')

local tconcat = table.concat

function _M:new(name)

    local fields = dbInit.sqlTableFields(name)
    fields.alterMode = 'add'
    fields.createMode = true
    local this = {
        name = name,
        fields = fields
    }
 
    setmetatable(this, mt)

    return this
end
 
function _M:sql(dbType)
 
    local name = self.name
    local fields = self.fields

    if not name then
        error('table name has not been set')
    end

    local strSql = "create table "..pub.sqlWrapName(name, dbType).." "..fields:sql(dbType)

    return strSql
end

return _M

