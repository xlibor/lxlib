
local lx, _M = oo{
    _cls_ = '',
    _mix_ = 'validation.relaceAttr'
}

local app, lf, tb, str = lx.kit()

local sizeRules = tb.flip{'Size', 'Between', 'Min', 'Max'}
local numericRules = tb.flip{'Numeric', 'Integer'}

function _M:ctor()

    self.sizeRules = tb.flip{'Size', 'Between', 'Min', 'Max'}
    self.numericRules = tb.flip{'Numeric', 'Integer'}
end

function _M.__:getMsg(attr, rule)

    local lowerRule = str.snake(rule)
    local inlineMsg = self:getFromLocalArray(attr, lowerRule)
    
    if inlineMsg then
        
        return inlineMsg
    end
    local customKey = 'validation.custom.' .. attr .. '.' .. lowerRule
    local customMsg = self:getCustomMsgFromTranslator(customKey)

    if customMsg ~= customKey then
        
        return customMsg
    elseif self.sizeRules[rule] then
        
        return self:getSizeMsg(attr, rule)
    end
    
    local key = 'validation.' .. lowerRule
    local value = self:trans(key)
    if key ~= (value) then
        
        return value
    end
    
    return self:getFromLocalArray(attr, lowerRule, self.fallbackMsgs) or key
end

function _M.__:trans(key)

    local t = self.translator:trans(key)

    return t
end

function _M.__:getFromLocalArray(attr, lowerRule, source)

    source = source or self.customMsgs
    local keys = {"{attr}.{lowerRule}", lowerRule}
    
    for _, key in pairs(keys) do
        for _, sourceKey in pairs(tb.keys(source)) do
            if str.is(sourceKey, key) then
                
                return source[sourceKey]
            end
        end
    end
end

function _M.__:getCustomMsgFromTranslator(key)

    local msg = self:trans(key)
    if msg ~= key then
        
        return msg
    end
    
    local shortKey = str.rereplace(key, 'validation\\.custom\\.', '')

    return self:getWildcardCustomMsgs(
        tb.dot(self:trans('validation.custom')),
        shortKey, key
    )
end

function _M.__:getWildcardCustomMsgs(msgs, search, default)

    for key, msg in pairs(msgs) do
        if search == key or str.contains(key, {'*'}) and str.is(key, search) then
            
            return msg
        end
    end
    
    return default
end

function _M.__:getSizeMsg(attr, rule)

    local lowerRule = str.snake(rule)
    
    local typ = self:getAttrType(attr)
    local key = 'validation.' .. lowerRule .. '.' .. typ
    
    return self:trans(key)
end

function _M.__:getAttrType(attr)

    if self:hasRule(attr, self.numericRules) then
        
        return 'numeric'
    elseif self:hasRule(attr, {'Array'}) then
        
        return 'array'
    elseif lf.isA(self:getValue(attr), 'uploadedFile') then
        
        return 'file'
    end
    
    return 'string'
end

function _M:makeReplacements(msg, attr, rule, parameters)

    msg = self:replaceAttrPlaceholder(msg, self:getDisplayableAttr(attr))
    replacer = 'replace' .. rule

    if self.replacers[str.snake(rule)] then

        return self:callReplacer(msg, attr, str.snake(rule), parameters)
    elseif self:__has(replacer) then
        replacer = self[replacer]
        return replacer(self, msg, attr, rule, parameters)
    end
    
    return msg
end

function _M.__:getDisplayableAttr(attr)

    local line
    local primaryAttr = self:getPrimaryAttr(attr)
    local expectedAttrs = attr ~= primaryAttr and {attr, primaryAttr} or {attr}
    for _, name in pairs(expectedAttrs) do
        
        if self.customAttrs[name] then
            
            return self.customAttrs[name]
        end
        line = self:getAttrFromTranslations(name)
        
        if line then
            
            return line
        end
    end
    
    if self.implicitAttrs[primaryAttr] then
        
        return attr
    end
    
    return str.replace(str.snake(attr), '_', ' ')
end

function _M.__:getAttrFromTranslations(name)

    return tb.get(self:trans('validation.attrs'), name)
end

function _M.__:replaceAttrPlaceholder(msg, value)

    return str.replace(msg, {':attr', ':ATTR', ':Attr'}, {value, str.upper(value), str.ucfirst(value)})
end

function _M:getDisplayableValue(attr, value)

    if self.customValues[attr][value] then
        
        return self.customValues[attr][value]
    end
    local key = 'validation.values.' .. attr .. '.' .. value
    local line = self:trans(key)
    if line ~= key then
        
        return line
    end
    
    return value
end

function _M.__:getAttrList(values)

    local attrs = {}
    
    for key, value in pairs(values) do
        attrs[key] = self:getDisplayableAttr(value)
    end
    
    return attrs
end

function _M.__:callReplacer(msg, attr, rule, ...)

    local callback = self.replacers[rule]
    if lf.isFunc(callback) then
        
        return callback(...)
    elseif lf.isStr(callback) then
        
        return self:callClassBasedReplacer(callback, msg, attr, rule, ...)
    end
end

function _M.__:callClassBasedReplacer(callback, ...)

    local class, method = str.parseCallback(callback, 'replace')
    
    return lf.call({app:make(class), method}, ...)
end

return _M

