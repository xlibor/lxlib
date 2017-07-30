
local lx, _M = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

function _M:authorize(ability, arguments)

    arguments = arguments or {}
    local ability, arguments = self:parseAbilityAndArguments(ability, arguments)
    
    return app.gate:authorize(ability, arguments)
end

function _M:authorizeForUser(user, ability, arguments)

    arguments = arguments or {}
    local ability, arguments = self:parseAbilityAndArguments(ability, arguments)
    
    return app.gate:forUser(user):authorize(ability, arguments)
end

function _M.__:parseAbilityAndArguments(ability, arguments)

    if lf.isStr(ability) and str.strpos(ability, '%.') == false then
        
        return ability, arguments
    end
    local method = lx.getFunc(3)
    
    return self:normalizeGuessedAbilityName(method), ability
end

function _M.__:normalizeGuessedAbilityName(ability)

    local map = self:resourceAbilityMap()
    
    return map[ability] or ability
end

function _M:authorizeResource(model, parameter, options, request)

    options = options or {}
    local modelName
    parameter = parameter or str.lower(model.__name)
    local middleware = {}

    for method, ability in pairs(self:resourceAbilityMap()) do
        modelName = tb.inList({'index', 'create', 'store'}, method)
            and model or parameter
        tb.mapd(middleware, fmt("can:%s,%s", ability, modelName), method)
    end

    for middlewareName, methods in pairs(middleware) do
        self:middleware(middlewareName, options):only(methods)
    end
end

function _M.__:resourceAbilityMap()

    return {
        show        = 'view',
        create      = 'create',
        store       = 'create',
        edit        = 'update',
        update      = 'update',
        destroy     = 'delete'
    }
end

return _M

