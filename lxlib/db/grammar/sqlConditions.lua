
local _M = {
    _cls_ = '@sqlConditions'
}
local mt = { __index = _M }

local lx = require('lxlib')
local dbInit = lx.db
local pub = require('lxlib.db.pub')
local slen = string.len

function _M:new()

    local this = {
        logicalOperators = {},
        conditions = {},
        notOperators = {},
        _tmpNotOperator = false,
        _needNot = false
    }
    
    setmetatable(this, mt)

    return this
end

function _M:count()

    return #self.conditions
end

function _M:clone(deep)

    if type(deep) == 'nil' then
        deep = true
    end
    
    local clone = self:new()
    local cdt,cdts
    for k, v in pairs(this or {}) do
        clone[k] = v
    end
    if deep then
        cdts = clone.conditions
        if cdts then
            for i,v in ipairs(cdts) do
                if v.__cls == 'sqlCondition' then
                    cdts[i] = v:clone()
                else
                    cdts[i] = v:clone(deep)
                end
            end
        end
    end
    return clone
end

function _M:add(field, compareOperator, value, tbl)

    self:ensurePreLO()
    local cdt = dbInit.sqlCondition(field, compareOperator, value, tbl)
    tapd(self.conditions, cdt)
    if self._tmpNotOperator then
        tapd(self.notOperators, 'not ')
    else
        tapd(self.notOperators, '')
    end
    self._tmpNotOperator = false

    return cdt
end

function _M:addCondition(cdt)

    if not cdt then
        error('condition is nil')
    else
        if type(cdt) ~= 'table' then
            error('condtion is not table')
        end

        self:ensurePreLO()
        tapd(self.conditions, cdt)
        if self._tmpNotOperator then
            tapd(self.notOperators, 'not ')
        else
            tapd(self.notOperators, '')
        end
        self._tmpNotOperator = false
    end
end

function _M:addConditions(cdts)

    if not cdts then
        error('conditions is nil')
    else
        if type(cdts) ~= 'table' then
            error('conditions is not table')
        end

        self:ensurePreLO()
        tapd(self.conditions, cdts)
        if self._tmpNotOperator then
            tapd(self.notOperators, 'not ')
        else
            tapd(self.notOperators, '')
        end
        self._tmpNotOperator = false
    end
end

function _M:addInSelect(field, sqlSelect, tbl)
 
end

function _M:addSelect( )
 
end

function _M:addFieldCompare( )
 
end

-- ensurePreviousLogicalOperatorExists
function _M:ensurePreLO() 

    if #self.logicalOperators < #self.conditions then
        self:addLO('and')
    end
end

-- addLogicalOperator
function _M:addLO(lo)

    if not lo then lo = 'and' end

    if lo =='and' then
        tapd(self.logicalOperators, 'and')
        self._tmpNotOperator = false
    elseif lo == 'or' then
        tapd(self.logicalOperators, 'or')
        self._tmpNotOperator = false
    elseif lo == 'not' then
        self._tmpNotOperator = true
    elseif lo == 'and not' then
        self._tmpNotOperator = true
        tapd(self.logicalOperators, 'and')
    elseif lo == 'or not' then
        self._tmpNotOperator = true
        tapd(self.logicalOperators, 'or')
    else
        error('not support logicalOperator.' .. lo)
    end

end

function _M:sql(dbType)

    local sql = {}
    local t

    local count = #self.conditions
    for i,v in ipairs(self.conditions) do
        if i > 1 then
            tapd(sql, ' '..self.logicalOperators[i-1]..' ')
        end
        if type(v) == 'table' then
            local clsName = v.__cls
            if clsName then
                if clsName == 'sqlCondition' then
                    tapd(sql, self.notOperators[i])
                    t = v:sql(dbType); tapd(sql, t)
                elseif clsName == 'sqlConditions' then
                    tapd(sql, self.notOperators[i])
                    t = v:sql(dbType); tapd(sql, '('..t..')')
                elseif clsName == 'sqlConditionSelect' then
                    t = v:sql(dbType); tapd(sql, t)
                elseif clsName == 'sqlConditionFieldCompare' then
                    t = v:sql(dbType); tapd(sql, t)    
                elseif clsName == 'sqlConditionInSelect' then
                    t = v:sql(dbType); tapd(sql, t)    
                else
                    error('condition not support cls.'..clsName)
                end
            else
                error('unknown sqlClass')
            end
        else
            error('condition must be table')
        end
    end

    local strSql = table.concat(sql)
     
    if slen(strSql) == 0 then
        strSql = '()'
    end

    return strSql
end
 
local function mtMethod(p1, p2, optType)
    local tCdts,newTopCdts
    local p1Type, p2Type, lo
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
        error('unsupport optType.'..optType)
    end
    
    if optType == 'mul' or optType == 'div' then
        addBrackets = true
    end
    
    local t2Len, tLos
    
    if p1Type == 'table' and p2Type == 'table' then
        p1Cls, p2Cls = t1.__cls, t2.__cls
        if p1Cls == 'sqlConditions' and p2Cls == 'sqlCondition' then
            t1 = pub.checkNestCdts(t1)
            tCdts = dbInit.sqlConditions()
            if t1._needNot then t1._needNot = false; tCdts:addLO('not') end
            tCdts:addConditions(t1)
            tCdts:addLO(lo)
            if t2._needNot then t2._needNot = false; tCdts:addLO('not') end
            tCdts:addCondition(t2)
        elseif p1Cls == 'sqlConditions' and p2Cls == 'sqlConditions' then 
            t1 = pub.checkNestCdts(t1)
            t2 = pub.checkNestCdts(t2)
            tCdts = dbInit.sqlConditions()
            if t1._needNot then t1._needNot = false; tCdts:addLO('not') end
            tCdts:addConditions(t1)
            tCdts:addLO(lo)
            if t2._needNot then t2._needNot = false; tCdts:addLO('not') end
            tCdts:addConditions(t2)
        else
            error('not support '..p1Cls..' with '..p2Cls)
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
    local p1Type, p2Type, lo
    local p1Type, p2Type = type(p1), type(p2)
    local p1Cls, p2Cls
    local addBrackets
    local t, value
    local cloneEles ={}
    local tEle,tEles,tSubEle
    
    if p1Type == 'table' and p2Type == 'table' then
        p1Cls, p2Cls = p1.__cls, p2.__cls
        if p1Cls == 'sqlConditions' and (not p2Cls) then
            t = p1:clone()
            cloneEles = pub.getCdtsEles(t,#p2)
            for i,v in ipairs(cloneEles) do 
                cloneEles[i].value = p2[i]
            end
        elseif (not p1Cls) and p2Cls == 'sqlConditions' then
            t = p2:clone()
            cloneEles = pub.getCdtsEles(t,#p1)
            for i,v in ipairs(cloneEles) do 
                cloneEles[i].field = p1[i]
            end
        end
    elseif p1Type == 'table' then
        t = p1:clone()
        tEles = pub.getCdtsEles(t,1)
        if tEles then
            tEle = tEles[1]
            tEle.value = p2
        else
        
        end
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

return _M

