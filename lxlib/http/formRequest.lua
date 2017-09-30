
local lx, _M, mt = oo{
    _cls_   = '',
    _bond_  = 'validateWhenResolvedBond',
    _mix_   = 'validateWhenResolvedMix'
}

local app, lf, tb, str, new = lx.kit()
local throw = lx.throw

function _M:new(req)

    local this = {
        req             = req,
        redirector      = nil,
        redirect        = nil,
        redirectRoute   = nil,
        redirectAction  = nil,
        errorBag        = 'default',
        dontFlash       = {'password', 'password_confirmation'}
    }

    return oo(this, mt)
end

function _M.__:getValidatorInstance()
    
    local validator = app.validator
    return validator:make(self:validationData(), self:rules(), self:msgs(), self:attrs())
end

function _M.__:validationData()

    return self.req.all
end

function _M.__:failedValidation(validator)

    throw('validationException', validator, self:response(self:formatErrors(validator)))
end

function _M.__:passesAuthorization()

    if self:__has('authorize') then
        
        return self:authorize()
    end
    
    return false
end

function _M.__:failedAuthorization()

    throw('httpResponseException', self:forbiddenResponse())
end

function _M:response(errors)

    if self.expectsJson then
        
        return new('jsonResponse' ,errors, 422)
    end
    
    return app:get('redirect')
        :to(self:getRedirectUrl())
        :withInput(self.req:except(self.dontFlash))
        :withErrors(errors, self.errorBag)
end

function _M:forbiddenResponse()

    return new('response' ,'Forbidden', 403)
end

function _M.__:formatErrors(validator)

    return validator:getMsgBag():toArr()
end

function _M.__:getRedirectUrl()

    local url = app.url
    if self.redirect then
        
        return url:to(self.redirect)
     elseif self.redirectRoute then
        
        return url:route(self.redirectRoute)
     elseif self.redirectAction then
        
        return url:action(self.redirectAction)
    end
    
    return url:previous()
end

function _M:msgs()

    return {}
end

function _M:attrs()

    return {}
end

function _M:_get_(key)

    return self.req[key]
end

function _M:getReq()

    return self.req
end

function _M:_run_(method)

    return 'getReq'
end

return _M

