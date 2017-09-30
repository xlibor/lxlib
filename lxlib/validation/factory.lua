
local lx, _M, mt = oo{
    _cls_ = '',
    -- _bond_ = 'factoryContract'
}

local app, lf, tb, str, new = lx.kit()

function _M:new(translator)

    local this = {
        translator = translator,
        verifier = nil,
        extensions = {},
        implicitExtensions = {},
        replacers = {},
        fallbackMsgs = {},
        resolver = nil
    }
    
    return oo(this, mt)
end

function _M:make(data, rules, msgs, customAttrs)

    customAttrs = customAttrs or {}
    msgs = msgs or {}
    
    local validator = self:resolve(data, rules, msgs, customAttrs)

    if self.verifier then
        validator:setVerifier(self.verifier)
    end

    self:addExtensions(validator)
    
    return validator
end

function _M:validate(data, rules, msgs, customAttrs)

    customAttrs = customAttrs or {}
    msgs = msgs or {}
    self:make(data, rules, msgs, customAttrs):validate()
end

function _M.__:resolve(data, rules, msgs, customAttrs)

    if not self.resolver then

        return new('validation.validator', self.translator, data, rules, msgs, customAttrs)
    end

    return lf.call(self.resolver, self.translator, data, rules, msgs, customAttrs)
end

function _M.__:addExtensions(validator)

    validator:addExtensions(self.extensions)
    
    validator:addImplicitExtensions(self.implicitExtensions)
    validator:addReplacers(self.replacers)
    validator:setFallbackMsgs(self.fallbackMsgs)
end

function _M:extend(rule, extension, msg)

    self.extensions[rule] = extension
    if msg then
        self.fallbackMsgs[str.snake(rule)] = msg
    end
end

function _M:extendImplicit(rule, extension, msg)

    self.implicitExtensions[rule] = extension
    if msg then
        self.fallbackMsgs[str.snake(rule)] = msg
    end
end

function _M:replacer(rule, replacer)

    self.replacers[rule] = replacer
end

function _M:getTranslator()

    return self.translator
end

function _M:getVerifier()

    return self.verifier
end

function _M:setVerifier(verifier)

    self.verifier = verifier
end

return _M

