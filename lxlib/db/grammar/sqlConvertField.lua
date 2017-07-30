
local _M ={
    _cls_ = '@sqlConvertField'
}

local mt = { __index = _M }
 
local sfind = string.find
local ssub = string.sub

local pub = require('lxlib.db.pub')

function _M:new(fieldName, ...)
    local this = {
        dbType = 'mysql',
        fieldName = fieldName,
        otherFields = {...},
        asExpression = false,
--        sqlStatement = '',
--        operator = '',
--        operatorValue = ''
    }
 
    setmetatable(this, mt)

    return this
end
    
function _M:setExpression(expression)

    self.asExpression = true
    self.expression = expression

    return self
end

function _M:make(operatorOrStatement, value)

    if value then
        self.operator = operatorOrStatement
        self.operatorValue = value
    else 
        if self.fieldName then
            local i,j = sfind(operatorOrStatement,'%%s')
            if not i then
                operatorOrStatement = '%s '..operatorOrStatement
            end
        end
        self.sqlStatement = operatorOrStatement
    end
    
    return self
end

function _M:sql(dbType)

    local sql
    local t, tTblName
    local tSql
    
    if self.asExpression then
        
        return self.expression
    end

    if not self.fieldName then
        return self.sqlStatement or ''
    end
    
    local tFieldName = self:_getFieldName(self.fieldName, dbType)

    if not self.sqlStatement then
        if self.operator then
 
            sql = tFieldName..' '..self.operator..' '
            t = pub.sqlConvertValue(self.operatorValue)
            sql = sql..t
        else
             
            sql = tFieldName
        end
    else
        local otherFields = self.otherFields or {}
        if #otherFields == 0 then
            sql = string.format(self.sqlStatement, tFieldName)
        else
            local fieldNames = {tFieldName}

            for _, fieldName in ipairs(otherFields) do
                tFieldName = self:_getFieldName(fieldName, dbType)
                tapd(fieldNames, tFieldName)
            end
 
            sql = string.format(self.sqlStatement, unpack(fieldNames))
            -- Todo:formatFields
        end
    end
    
    return sql
end

function _M:_getFieldName(fieldName, dbType)
    if not fieldName then return end
    local t, tFieldName, tTblName
    local sCin = pub.sqlWrapName
    local i,j = sfind(fieldName,'%.')
    if i then
        tTblName = ssub(fieldName,1,i-1)
        tFieldName = ssub(fieldName,i+1)
        tFieldName = sCin(tTblName,dbType)..'.'..sCin(tFieldName,dbType)
    else
        tFieldName = sCin(fieldName,dbType)
    end
    
    return tFieldName
end
 
mt.__call = function(self,...)
 
    return self:make(...)
end

return _M

