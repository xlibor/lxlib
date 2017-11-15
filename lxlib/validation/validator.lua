
local lx, _M, mt = oo{
    _cls_ = '',
    _bond_ = 'validatorBond',
    _mix_ = {'lxlib.validation.base.formatMsg', 'lxlib.validation.base.validateAttr'},
    fileRules = {'File', 'Image', 'Mimes', 'Mimetypes', 'Min', 'Max', 'Size', 'Between', 'Dimensions'},
    implicitRules = {'Required', 'Filled', 'RequiredWith', 'RequiredWithAll', 'RequiredWithout', 'RequiredWithoutAll', 'RequiredIf', 'RequiredUnless', 'Accepted', 'Present'},
    dependentRules = {'RequiredWith', 'RequiredWithAll', 'RequiredWithout', 'RequiredWithoutAll', 'RequiredIf', 'RequiredUnless', 'Confirmed', 'Same', 'Different', 'Unique', 'Before', 'After', 'BeforeOrEqual', 'AfterOrEqual'}
}

local app, lf, tb, str, new = lx.kit()
local throw = lx.throw
local ssub, sfind = string.sub, string.find

local RuleParser = lx.use('lxlib.validation.ruleParser')
local ValidationData = lx.use('lxlib.validation.validationData')

function _M:new()

    local this = {
        verifier = nil,
        failedRules = {},
        _msgs = nil,
        rules = nil,
        currentRule = nil,
        implicitAttrs = {},
        afters = {},
        fallbackMsgs = {},
        customValues = {},
        extensions = {},
        replacers = {}
    }
    
    return oo(this, mt)
end

function _M:ctor(translator, data, rules, msgs, customAttrs)

    customAttrs = customAttrs or {}
    msgs = msgs or {}
    self.initialRules = rules
    self.translator = translator
    self.customMsgs = msgs
    self.data = self:parseData(data)
    self.customAttrs = customAttrs
    self:setRules(rules)
end

function _M:parseData(data)

    local value
    local newData = {}
    for key, value in pairs(data) do
        if lf.isTbl(value) then
            if not value.__cls then
                value = self:parseData(value)
            end
        end
        newData[key] = value
    end
    
    return newData
end

function _M:after(callback)

    tapd(self.afters, function()
        
        return callback(self)
    end)
    
    return self
end

function _M:passes()

    local attr
    self._msgs = new('msgBag')

    for attr, rules in pairs(self.rules) do

        for _, rule in pairs(rules) do
            self:validateAttr(attr, rule)
            if self:shouldStopValidating(attr) then
                break
            end
        end
    end
    
    for _, after in pairs(self.afters) do
        lf.call(after)
    end
    
    return self._msgs:isEmpty()
end

function _M:fails()

    return not self:passes()
end

function _M:validate()

    if self:fails() then
        throw('validationException', self)
    end
end

function _M.__:validateAttr(attr, rule)

    local parameters
    self.currentRule = rule
    rule, parameters = unpack(RuleParser.parse(rule))
    if rule == '' then
        
        return
    end

    local keys = self:getExplicitKeys(attr)
    
    if keys and self:dependsOnOtherFields(rule) then
        parameters = self:replaceAsterisksInParameters(parameters, keys)
    end
    local value = self:getValue(attr)

    if lf.isA(value, 'uploadedFile')
        and not value:isValid()
        and self:hasRule(attr, tb.merge(self.fileRules, self.implicitRules)) then
        
        return self:addFailure(attr, 'uploaded', {})
    end
    
    local validatable = self:isValidatable(rule, attr, value)

    local method = 'validate' .. rule

    if validatable and not self[method](self, attr, value, parameters, self) then
        self:addFailure(attr, rule, parameters)
    end
end

function _M.__:dependsOnOtherFields(rule)

    return tb.inList(self.dependentRules, rule)
end

function _M.__:getExplicitKeys(attr)

    local pattern = str.replace(
        str.pregQuote(self:getPrimaryAttr(attr)),
        '\\*', '([^\\.]+)'
    )

    local keys = str.rematch(attr, pattern)
    if keys then
        tb.shift(keys)
        
        return keys
    end
    
    return {}
end

function _M.__:getPrimaryAttr(attr)

    for unparsed, parsed in pairs(self.implicitAttrs) do
        if tb.inList(parsed, attr) then
            
            return unparsed
        end
    end
    
    return attr
end

function _M.__:replaceAsterisksInParameters(parameters, keys)

    return tb.map(parameters, function(field)
        
        return fmt(str.replace(field, '*', '%s'), unpack(keys))
    end)
end

function _M.__:isValidatable(rule, attr, value)

    return self:presentOrRuleIsImplicit(rule, attr, value)
        and self:passesOptionalCheck(attr)
        and self:isNotNullIfMarkedAsNullable(attr, value)
        and self:hasNotFailedPreviousRuleIfRule(rule, attr)
end

function _M.__:presentOrRuleIsImplicit(rule, attr, value)

    if lf.isStr(value) and str.trim(value) == '' then
        
        return self:isImplicit(rule)
    end
    
    return self:validatePresent(attr, value) or self:isImplicit(rule)
end

function _M.__:isImplicit(rule)

    return tb.inList(self.implicitRules, rule)
end

function _M.__:passesOptionalCheck(attr)

    if not self:hasRule(attr, {'Sometimes'}) then
        
        return true
    end
    local data = ValidationData.initAndGatherData(attr, self.data)
    
    return tb.has(attr, data) or tb.inList(tb.keys(self.data), attr)
end

function _M.__:isNotNullIfMarkedAsNullable(attr, value)

    if not self:hasRule(attr, {'Nullable'}) then
        
        return true
    end
    
    return value
end

function _M.__:hasNotFailedPreviousRuleIfRule(rule, attr)

    return tb.inList({'Unique', 'Exists'}, rule)
        and not self.msgs:has(attr) or true
end

function _M.__:shouldStopValidating(attr)

    if self:hasRule(attr, {'Bail'}) then
        
        return self.msgs:has(attr)
    end
    if self.failedRules[attr]
        and tb.inList(tb.keys(self.failedRules[attr]), 'uploaded') then
        
        return true
    end
    
    return self:hasRule(attr, self.implicitRules)
        and self.failedRules[attr]
        and tb.same(tb.keys(self.failedRules[attr]), self.implicitRules)
end

function _M.__:addFailure(attr, rule, parameters)

    self.msgs:add(attr,
        self:makeReplacements(self:getMsg(attr, rule), attr, rule, parameters)
    )
    tb.set(self.failedRules, attr, rule, parameters)
end

function _M:valid()

    if not self._msgs then
        self:passes()
    end
    
    return tb.diffKey(self.data, self:attrsHaveMsgs())
end

function _M:invalid()

    if not self._msgs then
        self:passes()
    end
    
    return tb.cross(self.data, self:attrsHaveMsgs())
end

function _M.__:attrsHaveMsgs()

    return Col(self.msgs:toArr()):map(function(msg, key)
        
        return str.first(key, '.')
    end):unique():flip():all()
end

function _M:failed()

    return self.failedRules
end

function _M.d__:msgs()

    if not self._msgs then
        self:passes()
    end
    
    return self._msgs
end

function _M:errors()

    return self.msgs
end

function _M:getMsgBag()

    return self.msgs
end

function _M:hasRule(attr, rules)

    return self:getRule(attr, rules)
end

function _M.__:getRule(attr, rules)

    if not tb.has(self.rules, attr) then
        
        return
    end
    rules = lf.needList(rules)
    for _, rule in pairs(self.rules[attr]) do
        local rule, parameters = unpack(RuleParser.parse(rule))
        if tb.inList(rules, rule) then
            
            return {rule, parameters}
        end
    end
end

function _M:attrs()

    return self:getData()
end

function _M:getData()

    return self.data
end

function _M:setData(data)

    self.data = self:parseData(data)
    self:setRules(self.initialRules)
    
    return self
end

function _M.__:getValue(attr)

    return tb.get(self.data, attr)
end

function _M:getRules()

    return self.rules
end

function _M:setRules(rules)

    self.initialRules = rules
    self.rules = {}
    self:addRules(rules)
    
    return self
end

function _M:addRules(rules)

    local response = new('lxlib.validation.ruleParser', self.data):explode(rules)
    self.rules = tb.deepMerge(self.rules, response.rules)

    self.implicitAttrs = tb.merge(self.implicitAttrs, response.implicitAttrs)
end

function _M:sometimes(attr, rules, callback)

    local payload = new('chain' ,self:getData())
    if lf.call(callback, payload) then
        for _, key in pairs(attr) do
            self:addRules({key = rules})
        end
    end
    
    return self
end

function _M:addExtensions(extensions)

    local keys
    if extensions then
        keys = tb.map(tb.keys(extensions), str.snake)
        extensions = tb.combine(keys, tb.values(extensions))
    end

    self.extensions = tb.merge(self.extensions, extensions)
end

function _M:addImplicitExtensions(extensions)

    self:addExtensions(extensions)
    for rule, extension in pairs(extensions) do
        tapd(self.implicitRules, str.studly(rule))
    end
end

function _M:addExtension(rule, extension)

    self.extensions[str.snake(rule)] = extension
end

function _M:addImplicitExtension(rule, extension)

    self:addExtension(rule, extension)
    tapd(self.implicitRules, str.studly(rule))
end

function _M:addReplacers(replacers)

    local keys
    if replacers then
        keys = tb.map(tb.keys(replacers), str.snake)
        replacers = tb.combine(keys, tb.values(replacers))
    end
    self.replacers = tb.merge(self.replacers, replacers)
end

function _M:addReplacer(rule, replacer)

    self.replacers[str.snake(rule)] = replacer
end

function _M:setCustomMsgs(msgs)

    self.customMsgs = tb.merge(self.customMsgs, msgs)
end

function _M:setAttrNames(attrs)

    self.customAttrs = attrs
    
    return self
end

function _M:addCustomAttrs(customAttrs)

    self.customAttrs = tb.merge(self.customAttrs, customAttrs)
    
    return self
end

function _M:setValueNames(values)

    self.customValues = values
    
    return self
end

function _M:addCustomValues(customValues)

    self.customValues = tb.merge(self.customValues, customValues)
    
    return self
end

function _M:setFallbackMsgs(msgs)

    self.fallbackMsgs = msgs
end

function _M:getVerifier()

    if not self.verifier then
        throw('runtimeException', 'verifier has not been set.')
    end
    
    return self.verifier
end

function _M.__:getVerifierFor(connection)

    local verifier = self:getVerifier()

    verifier:setConnection(connection)

    return verifier
end

function _M:setVerifier(verifier)

    self.verifier = verifier
end

function _M:getTranslator()

    return self.translator
end

function _M:setTranslator(translator)

    self.translator = translator
end

function _M.__:callExtension(rule, parameters)

    local callback = self.extensions[rule]
    if lf.isFun(calllback) then
        
        return callback(unpack(parameters))
    elseif lf.isStr(callback) then
        
        return self:callClassBasedExtension(callback, parameters)
    end
end

function _M.__:callClassBasedExtension(callback, ...)

    local class, method = str.parseCallback(callback, 'validate')
    
    return lf.call({app:make(class), method}, parameters)
end

function _M:_run_(method)

    local rule = str.snake(str.substr(method, 9))
    if self.extensions[rule] then
        return function(self, ...)
            return self:callExtension(rule, parameters)
        end
    end

    throw('badMethodCallException', 'Method [' .. method .. '] does not exist.')
end

return _M

