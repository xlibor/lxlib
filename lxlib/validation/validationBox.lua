
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'box'
}

local app, lf, tb, str, new = lx.kit()

function _M:reg()

    self:regDepends()

    self:regVerifier()
    self:regFactory()
end

function _M.__:regFactory()

    local factory = 'lxlib.validation.factory'

    app:single('validator', factory, function()

        local validator = new(factory, app.translator)
        
        if app.db and app['validation.verifier'] then
            validator:setVerifier(app['validation.verifier'])
        end
        
        return validator
    end)
end

function _M.__:regVerifier()

    app:single('validation.verifier', function()
        
        return new('dbVerifier', app.db)
    end)
end

function _M.__:regDepends()
    
    app:bindFrom('lxlib.validation', {
        validationRuleParser        = 'ruleParser',
        validationData              = 'validationData',
        validationRule              = 'validationRule',
        validateRequest             = 'validateRequest',
        dbVerifier                  = 'dbVerifier',
        ['validation.validator']    = 'validator'  
    })

    app:bindFrom('lxlib.validation.base', {
        ['validation.formatMsg']        = 'formatMsg',
        ['validation.validateAttr']     = 'validateAttr',
        ['validation.relaceAttr']       = 'replaceAttr',
    })

    app:bindFrom('lxlib.validation.rules', {
        ['validation.rules.dimensions']     = 'dimensions',
        ['validation.rules.exists']         = 'exists',
        ['validation.rules.in']             = 'in',
        ['validation.rules.notin']          = 'notin',
        ['validation.rules.unique']         = 'unique',
    })

    app:bindFrom('lxlib.validation.excp', {
        validationException     = 'validationException',
        unauthorizedException   = 'unauthorizedException'
    })

    app:bond('verifierBond', 'lxlib.validation.bond.verifier')
    app:bond('validatorBond', 'lxlib.validation.bond.validator')
end

function _M:boot()

end

function _M:provides()

    return {'validator', 'validation.presence'}
end

return _M

