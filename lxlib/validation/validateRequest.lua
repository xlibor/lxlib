
local lx, _M = oo{
    _cls_ = ''
}

local app, lf, tb, str, new = lx.kit()
local throw = lx.throw
local redirect = lx.h.redirect

function _M:validateWith(validator, request)

    request = request or app.request
    if lf.isTbl(validator) then
        validator = self:getValidationFactory():make(request.all, validator)
    end
    if validator:fails() then
        self:throwValidationException(request, validator)
    end
end

function _M:validate(request, rules, msgs, customAttributes)

    customAttributes = customAttributes or {}
    msgs = msgs or {}
    local validator = self:getValidationFactory():make(
        request.all, rules, msgs, customAttributes
    )
    if validator:fails() then

        self:throwValidationException(request, validator)
    end
end

function _M:validateWithBag(errorBag, request, rules, msgs, customAttributes)

    customAttributes = customAttributes or {}
    msgs = msgs or {}
    self:withErrorBag(errorBag, function()
        self:validate(request, rules, msgs, customAttributes)
    end)
end

function _M.__:withErrorBag(errorBag, callback)

    self.validatesRequestErrorBag = errorBag
    callback()
    self.validatesRequestErrorBag = nil
end

function _M.__:throwValidationException(request, validator)

    throw('validationException',
        validator,
        self:buildFailedValidationResponse(
            request, self:formatValidationErrors(validator)
        )
    )
end

function _M.__:buildFailedValidationResponse(request, errors)

    if request.expectsJson then
        
        return new('jsonResponse', errors, 422)
    end

    return redirect()
        :to(self:getRedirectUrl())
        :withInput(request:input())
        :withErrors(errors, self:errorBag())
end

function _M.__:formatValidationErrors(validator)

    return validator:errors():getMsgs()
end

function _M.__:errorBag()

    return self.validatesRequestErrorBag or 'default'
end

function _M.__:getRedirectUrl()

    return app.url:previous()
end

function _M.__:getValidationFactory()

    return app.validator
end

return _M

