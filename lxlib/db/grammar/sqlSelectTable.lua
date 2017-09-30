
local _M = {
    _cls_ = '@sqlSelectTable'
}
local mt = { __index = _M }

local pub = require('lxlib.db.pub')

function _M:new(name, alias)
    local this = {
        name = name,
        alias = alias
    }
 
    setmetatable(this, mt)

    return this
end
 
function _M:sql(dbType)
    
    local sql
    sql = pub.sqlWrapName(self.name, dbType)
    if self.alias then
        sql = sql .. ' as ' .. pub.sqlWrapName(self.alias, dbType)
    end
    
    return sql
end
 
return _M