
local _M = {
    _cls_ = ''
}
local mt = { __index = _M }

local lx = require('lxlib')

local sfind, ssub = string.find, string.sub
local tconcat = table.concat
local ddt = require('lxlib.db.common').ddt

local split = lx.str.split

function _M.checkNestCdts(cdts)

    local t 
    local tNeedNot
    local tLen, tEle1 = #cdts.conditions, cdts.conditions[1]
    
    if tLen == 1 and tEle1.__cls == 'sqlConditions' then 
        tNeedNot = cdts._needNot
        t = tEle1
        t._needNot = tNeedNot
    end
    t= t or cdts
    return t
end

function _M.getCdtsEles(cdts, max, haveGet)
    local eles = {}
    local tEles = {}
    local getMax = max or 99
    local haveGet = haveGet or 0
    local t
    local tHaveGet = 0
    
    if cdts.__cls then
        cdts = cdts.conditions
    end
    
    for _,v in ipairs(cdts) do
        if haveGet < getMax then
            if v.__cls == 'sqlCondition' then
                tapd(eles,v)
                haveGet = haveGet+1
            else
                tEles, tHaveGet = _M.getCdtsEles(v,max,haveGet)
                for _,t in ipairs(tEles) do
                    eles[#eles+1] = t
                end
                haveGet = haveGet + tHaveGet
            end
        end
    end
    
    return eles, haveGet
end

function _M.addTablePre(tbl, field, dbType)
    local sqlField, tblPre
    local i,j
     
    local fieldCls
    if type(field) == 'table' then
        fieldCls = field.__cls
        if fieldCls == 'sqlConvertField' then
            return field:sql()
        end
    end

    if type(tbl) == 'table' and tbl.name then
        tblPre = tbl.alias or tbl.name
        tblPre = _M.sqlWrapName(tblPre, dbType) .. '.'
        i,j = sfind(field,'%.')
        if i then field = ssub(field,i+1) end
    else
        i,j = sfind(field,'%.')
        if i then
            local tblName = ssub(field,1,i-1)
            field = ssub(field,i+1)
            tblPre = _M.sqlWrapName(tblName, dbType) .. '.'
        end
    end

    tblPre = tblPre or ''
    sqlField = tblPre .. _M.sqlWrapName(field, dbType)
 
    return sqlField
end

function _M.sqlCastValue(value, dataType, dbType)
    
    local retValue = value
    local vType = type(value)
    local t
    if vType == 'table' then
        local tblCls = value.__cls
        if tblCls then
            if tblCls == 'sqlColumn' then
                retValue = value
            else
                retValue = value
            end
        else
            local tmp = {}
            for _,v in ipairs(value) do
                t = _M.sqlCastValue(v, dataType, dbType)
                tapd(tmp, t)
            end
            
            retValue = tmp
        end
    else
        local isInt, isStr
        isStr = (dataType == ddt.char) or (dataType == ddt.varchar)
        if not isStr then
            isInt = (dataType == ddt.int) or (dataType == ddt.tinyint)
        end

        if vType == 'userdata' then
            if value == ngx.null then 
                return value
            end 
        end

        if isStr and vType ~= 'string' then
            retValue = tostring(value)
        elseif isInt and vType ~= 'number' then
            retValue = tonumber(value)
        else
            retValue = value
        end
    end
    
    return retValue
end

function _M.sqlConvertField(field, dbType)
    
    local strField = ''
    local ft = type(field)
    if ft == 'table' then
        local fCls = field.__cls
        if fCls then
            if fCls == 'sqlConvertField' then
                strField  = field:sql()
            else
                error('not support field cls:'..fCls)
            end
        else
            error('not support field type: table')
        end
    end
    
    return strField
end

function _M.sqlConvertValue(value, dbType)

    local strValue = ''
    local vt = type(value)

    if vt == 'string' then
        value = ngx.quote_sql_str(value)
        if dbType == 'mysql' then
            strValue = value
        else
            strValue = value
        end
    elseif vt == 'number' then
        strValue = value
    elseif vt == 'boolean' then
        strValue = value and '1' or '0'
    elseif vt == 'table' then
        local vCls = value.__cls
        if vCls then
            if vCls == 'sqlConvertField' then
                strValue  = value:sql()
            elseif value:__is('strable') then
                strValue = value:toStr()
            else
                error('not support value cls:'..vCls)
            end
        else
            error('not support value type: table')
        end

    elseif vt == 'userdata' then
        if value == ngx.null then
            strValue = 'NULL'
        else
            error('not support value type: userdata')
        end
    elseif vt == 'nil' then
        if not lx.env then
            strValue = 'NULL'
        else
            error('not support value type: nil')
        end
    else
        error('not support value type: '..vt)
    end

    return strValue
end

function _M.sqlConvertWhereIn(value, co, dbType)

    local sql = {}
    local strSql, t
    local vt = type(value)
    local vTbl = {}
    
    if vt == 'table' then
        vTbl = value
    else
        error('whereIn value type must be table')
    end
 
    if #vTbl == 1 then
        t = _M.sqlConvertValue(vTbl[1], dbType)
        if t then
            if co == 'in' then
                strSql = '= ' .. t
            else
                strSql = '<> ' .. t
            end
        else
            error('whereIn values is invalid')
        end
    else
        for _, v in pairs(vTbl) do
            t = _M.sqlConvertValue(v, dbType)
            if t then
                tapd(sql, t)
            end
        end
        if #sql == 0 then
            error('invalid whereIn value')
        else
            strSql = co .. ' (' .. tconcat(sql, ',') .. ')'
        end
    end
 
    return strSql
end

function _M.sqlConvertWhereBetween(value, dbType)
    local sql = {}
    local strSql
 
    local vt = type(value)
    if vt == 'table' then
        tapd(sql, 'between ')
        t = _M.sqlConvertValue(value[1], dbType)
        tapd(sql, t)
        tapd(sql, ' and ')
        t = _M.sqlConvertValue(value[2], dbType)
        tapd(sql, t)
    else
        error('whereBetween value type must be table')
    end
    strSql = tconcat(sql)

    return strSql
end

function _M.sqlWrapName(name, dbType, preCheck)

    local idName

    if name == '*' then
        idName = '*'
    else
        if preCheck then
            if sfind(name, '[^%w_]') then
                error('invalid table or column name')
            end
        end

        if dbType == 'mysql' then
            idName = '`' .. name .. '`'
        else
            idName = name
        end
    end
    
    return idName
end

function _M.sqlConvertBooleanValue(value, compareOperator)
    
    if type(value) == 'boolean' then
        if value then
            if compareOperator == '=' then 
                compareOperator = '<>'
            else
                compareOperator = '='
            end
            value = false
        end
    end

    return value, compareOperator
end

return _M

