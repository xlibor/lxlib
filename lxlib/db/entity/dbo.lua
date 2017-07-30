
local _M = {
    _cls_    = ''
}

local mt = { __index = function(this, key)
    local addTableName = this._addTableName
    if addTableName then
        return this._tblName .. '.' .. key
    else
        return key
    end
end}

function _M:new(tableName, addTableName)

    local this

    if type(tableName) == 'table' then 

        this = tableName
        setmetatable(this, { __index = _M })

    else
        this = {
            _tblName = tableName,
            _addTableName = addTableName or false,
            tblDef = false,
            primaryKey = false
        }

        this._columns = this
        this._fullColumns = this

        setmetatable(this, mt)
    end

    return this
end

return _M

