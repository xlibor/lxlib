
local lx, _M = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

function _M:validate()

    self:prepareForValidation()
    local instance = self:getValidatorInstance()
    if not self:passesAuthorization() then
        self:failedAuthorization()
    elseif not instance:passes() then
        self:failedValidation(instance)
    end
end

function _M.__:prepareForValidation()
end

function _M.__:getValidatorInstance()

    return self:validator()
end

function _M.__:failedValidation(validator)

    lx.throw('validationException', validator)
end

function _M.__:passesAuthorization()

    if self:__has('authorize') then
        
        return self:authorize()
    end
    
    return true
end

function _M.__:failedAuthorization()

    lx.throw('unauthorizedException')
end

return _M

