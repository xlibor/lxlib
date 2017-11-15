
local lx, _M, mt = oo{
    _cls_       = '',
    _static_    = {

    }
}

local app, lf, tb, str = lx.kit()

local sfind = string.find
local static

function _M._init_(this)

    static = this.static
end

function _M:new(data)

    local this = {
        implicitAttributes = {}
    }
    
    return oo(this, mt)
end

function _M:explode(rules)

    self.implicitAttributes = {}
    rules = self:explodeRules(rules)
    
    return {rules = rules, implicitAttributes = self.implicitAttributes}
end

function _M.__:explodeRules(rules)

    for key, rule in pairs(rules) do
        if sfind(key, '%*') then
            rules = self:explodeWildcardRules(rules, key, {rule})
            rules[key] = nil
        else 
            rules[key] = self:explodeExplicitRule(rule)
        end
    end
    
    return rules
end

function _M.__:explodeExplicitRule(rule)

    if lf.isStr(rule) then
        
        return str.split(rule, '|')
    elseif lf.isObj(rule) then
        
        return {rule}
    else 
        
        return rule
    end
end

function _M.__:explodeWildcardRules(results, attribute, rules)

    local pattern = str.replace(str.pregQuote(attribute), '\\*', '[^\\.]*')
    local data = ValidationData.initializeAndGatherData(attribute, self.data)
    for key, value in pairs(data) do
        if str.startsWith(key, attribute) or str.rematch(key, pattern .. '\\z') then
            for _, rule in pairs(rules) do
                tb.mapd(self.implicitAttributes, attribute, key)
                results = self:mergeRules(results, key, rule)
            end
        end
    end
    
    return results
end

function _M:mergeRules(results, attribute, rules)

    rules = rules or {}
    if lf.isTbl(attribute) then
        for innerAttribute, innerRules in pairs(attribute) do
            results = self:mergeRulesForAttribute(results, innerAttribute, innerRules)
        end
        
        return results
    end
    
    return self:mergeRulesForAttribute(results, attribute, rules)
end

function _M.__:mergeRulesForAttribute(results, attribute, rules)

    local merge = self:explodeRules({rules})[1]
    results[attribute] = tb.merge(
        results[attribute]
            and self:explodeExplicitRule(results[attribute])
            or {},
        merge
    )
    
    return results
end

function _M.s__.parse(rules)

    if lf.isTbl(rules) then
        rules = static.parseArrayRule(rules)
    else 
        rules = static.parseStringRule(rules)
    end
    rules[1] = static.normalizeRule(rules[1])

    return rules
end

function _M.s__.parseArrayRule(rules)

    return {str.studly(str.trim(tb.get(rules, 1))), tb.slice(rules, 1)}
end

function _M.s__.parseStringRule(rules)

    local parameters = {}
    
    if sfind(rules, ':') then
        rules, parameter = str.div(rules, ':')
        parameters = static.parseParameters(rules, parameter)
    end
    
    return {str.studly(str.trim(rules)), parameters}
end

function _M.s__.parseParameters(rule, parameter)

    if str.lower(rule) == 'regex' then
        
        return {parameter}
    end

    return str.split(parameter, ',')
end

function _M.s__.normalizeRule(rule)

    local st = rule
    if st == 'Int' then
        
        return 'Integer'
    elseif st == 'Bool' then
        
        return 'Boolean'
    else 
        
        return rule
    end
end

return _M

