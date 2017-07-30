
local _M = {
    _cls_ = '@sqlJoin'
}
local mt = { __index = _M }

local sfind, ssub = string.find, string.sub

function _M:new()

    local this = {
        dbType = 'mysql',
        tableJoin = {},
        cdtField0 = '',
        cdtField1 = '',
        compareOperator = 'and',
        readySetOnFields = {}
    }
 
    setmetatable(this, mt)

    return this
end

function _M:setAllOn()

    local readySetOnFields = self.readySetOnFields

    if #readySetOnFields > 0 then
        local f0,cp,f1
        for i,field in pairs(readySetOnFields) do
            f0,cp,f1,lo = field[1],field[2],field[3],field[4]
            if i > 1 then
                if lo == 'or' then
                    self:or_(f0,cp,f1)
                else
                    self:and_(f0,cp,f1)
                end
            else
                self:runOn(f0,cp,f1)
            end
        end
    end

end

function _M:setUsing(cdtField)

    local i,j = sfind(cdtField, '%.')
    if i then
        cdtField = ssub(cdtField,i+1)
    end

    self:on(cdtField, '=', cdtField)
end

function _M:using(cdtField)

    self:setUsing(cdtField)

    return self
end

function _M:on(cdtField0, compareOperator, cdtField1)

    if not self.tableJoin then
        tapd(self.readySetOnFields, {cdtField0, compareOperator, cdtField1, 'and'} )
    else
        self:runOn(cdtField0, compareOperator, cdtField1)
    end

    return self
end

function _M:runOn(cdtField0, compareOperator, cdtField1)

    local co = compareOperator or '='

    self.tableJoin.conditions:add(cdtField0, co, cdtField1)
end

function _M:and_(cdtField0, compareOperator, cdtField1)

    local tablejoin = self.tableJoin

    if not self.tableJoin then
        tapd(self.readySetOnFields, {cdtField0, compareOperator, cdtField1, 'and'} )
    else
        self:runOn(cdtField0, compareOperator, cdtField1)
    end

    return self
end

function _M:or_(cdtField0, compareOperator, cdtField1)

    local tablejoin = self.tableJoin

    if not self.tableJoin then
        tapd(self.readySetOnFields, {cdtField0, compareOperator, cdtField1, 'or'} )
    else
        self.tableJoin.conditions:addLogicalOperator('or')
        self:runOn(cdtField0, compareOperator, cdtField1)
    end

    return self
end
 
return _M

