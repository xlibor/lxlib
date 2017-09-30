
local _M = {
    _cls_ = '@sqlCondition'
}
local mt = { __index = _M }
 
local pub = require('lxlib.db.pub')

local lx = require('lxlib')
local dbInit = lx.db

function _M:new(field, compareOperator, value, tbl)
    
    if type(value) == 'nil' then
        -- lx.throw('invalidColumnValueException', field, compareOperator)
    end

    local this = {
        field = field,
        table = tbl or {},
        value = value,
        co = compareOperator or '=',
        _needNot = false
    }
 
    setmetatable(this, mt)

    return this
end

function _M:clone()

    local clone = self:new(self.field, self.co, self.value, self.table)
    clone._needNot = self._needNot
    
    return clone
end

function _M:sql(dbType)

    local sql = {}
    local t
    local tbl, field, value, co = self.table, self.field, self.value, self.co
    local value, co = pub.sqlConvertBooleanValue(value, co)
    local isExpField = false

    if type(field) == 'table' then
        local strField = pub.sqlConvertField(field)
        tapd(sql, strField)
        isExpField = true
    else
        tapd(sql, pub.addTablePre(tbl, field, dbType) .. ' ')
    end

    local vt = type(value)

    if vt == 'userdata' then
        if co == '=' then
            t = 'is ' .. pub.sqlConvertValue(value, dbType)
            tapd(sql, t)
        elseif co == '<>' then
            t = 'is not ' .. pub.sqlConvertValue(value, dbType)
            tapd(sql, t)
        elseif co == 'is' then
            t = 'is null'
            tapd(sql, t)
        elseif co == 'is not' then
            t = 'is not null'
            tapd(sql, t)
        else
            error('nil specified as an SqlCondition value without using the equal or not equal operators')    
        end
    elseif vt == 'nil' then
        if not isExpField then
            error('sqlCondition value can not be nil')
        end
    else
        if co == 'in' or co == 'not in' then
            if #value == 0 then
                sql[#sql] = ' 0 = 1 '
            else
                t = pub.sqlConvertWhereIn(value, co, dbType)
                tapd(sql, t)
            end
        elseif co == 'between' then
            t = pub.sqlConvertWhereBetween(value, dbType)
            tapd(sql, t)
        elseif co == 'is' then
            t = 'is null'
            tapd(sql, t)
        elseif co == 'is not' then
            t = 'is not null'
            tapd(sql, t)
        else
            t = co .. ' ' .. pub.sqlConvertValue(value, dbType)
            tapd(sql, t)
        end
    end

    local strSql = table.concat(sql)
 
    return strSql
end
 
 
local function mtMethod(p1, p2, optType)

    local tCdts,newTopCdts
    local lo
    local p1Type, p2Type = type(p1), type(p2)
    local p1Cls, p2Cls
    local addBrackets
    
    local t1,t2 = p1, p2
    
    if optType == 'add' or optType == 'mul' then
        lo = 'and'
    elseif optType == 'sub' or optType == 'div' then
        lo = 'or'
    elseif optType == 'unm' then
        lo = ''
    elseif optType == 'mod' then
        lo = 'and not'
    else    
        error('unsupport optType:'..optType)
    end
    
    if optType == 'mul' or optType == 'div' then
        addBrackets = true
    end
    
    local t2Len, tLos
    
    if p1Type == 'table' and p2Type == 'table' then
        p1Cls, p2Cls = t1.__cls, t2.__cls
        if p1Cls == 'sqlCondition' and p2Cls == 'sqlCondition' then
            tCdts = dbInit.sqlConditions()
            if t1._needNot then t1._needNot = false; tCdts:addLO('not') end
            tCdts:addCondition(t1)
            tCdts:addLO(lo)
            if t2._needNot then  t2._needNot = false; tCdts:addLO('not') end
            tCdts:addCondition(t2)
        elseif p1Cls == 'sqlCondition' and p2Cls == 'sqlConditions' then 
            t2 = pub.checkNestCdts(t2)
            tCdts = dbInit.sqlConditions()
            if t1._needNot then t1._needNot = false; tCdts:addLO('not') end
            tCdts:addCondition(t1)
            tCdts:addLO(lo)
            tCdts:addConditions(t2)
        else
            error('not support '..(p1Cls or ' ')..' with '..(p2Cls or ' '))
        end

    elseif p1Type == 'table' then
        return p1
    elseif p2Type == 'table' then 
        return p2
    end
    
    if addBrackets then
        newTopCdts = dbInit.sqlConditions()
        newTopCdts:addConditions(tCdts)
    else
        newTopCdts = tCdts    
    end
    
    return newTopCdts 
end

local function mtAdd(p1, p2)

    return mtMethod(p1,p2, 'add')
end

local function mtSub(p1, p2)

    return mtMethod(p1,p2, 'sub') 
end

local function mtMul(p1, p2)

    return mtMethod(p1,p2, 'mul') 
end

local function mtDiv(p1, p2)

    return mtMethod(p1,p2, 'div') 
end

local function mtMod(p1, p2)

    return mtMethod(p1,p2, 'mod') 
end

local function mtUnm(p1)

    local t = p1:clone()
    t._needNot = not t._needNot
    return t
end

local function mtPow(p1, p2)

    local tCdts,newTopCdts
    local lo
    local p1Type, p2Type = type(p1), type(p2)
    local p1Cls, p2Cls
    local addBrackets
    local t, value
    
    if p1Type == 'table' and p2Type == 'table' then
        p1Cls, p2Cls = p1.__cls, p2.__cls
        if p1Cls == 'sqlCondition' and (not p2Cls) then
 
            t = p1:clone()
            t.value = p2
        elseif (not p1Cls) and p2Cls == 'sqlCondition' then
            t = p2:clone()
            t.field = p1[1]
        end
    elseif p1Type == 'table' then
        t = p1:clone()
        t.value = p2
    else
        t = p2:clone()
        t.field = p1
    end
    
    return t
end

mt.__add = mtAdd
mt.__sub = mtSub
mt.__mul = mtMul
mt.__div = mtDiv
mt.__unm = mtUnm
mt.__mod = mtMod
mt.__pow = mtPow

mt.__call = function(self,...)
    local cdt = self:new(...)
 
    return cdt
end

return _M

