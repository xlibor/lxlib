
local lx, _M = oo{
    _cls_ = ''
}

function _M:new(auth, gate)

    local this = {
        auth = auth,
        gate = gate
    }
end

function _M:handle(context, next, ability, models)

    self.auth:authenticate()
    self.gate:authorize(ability, self:getGateArguments(context.req, models))
    
    return next(context)
end

function _M.__:getGateArguments(request, models)

    if not models then
        
        return {}
    end
    
    return lx.col(models):map(function(model)
        
        return self:getModel(request, model)
    end):all()
end

function _M.__:getModel(request, model)

    return self:isClassName(model) and model or request:route(model)
end

function _M.__:isClassName(value)

    return str.strpos(value, '.') ~= false
end

return _M

