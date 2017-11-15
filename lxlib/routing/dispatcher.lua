
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

local router

function _M:new()
    
    local this = {
    }

    return oo(this, mt)
end

function _M:dispatch(route, req, ctler, method)

    local instance = self:makeCtler(ctler, route)

    return self:callWithinStack(instance, route, req, method)
end

local function filterBar(bar, instance, method)

    local barOptions = instance.barOptions

    local ret
    local option, only, except

    if next(barOptions) then
        option = barOptions[bar]
        if option then
            only = option.only
            if only then
                if not only[method] then
                    return false
                end
            else
                except = option.except
                if except then
                    if except[method] then
                        return false
                    end
                end
            end
        end
    else
        return true
    end

    return true
end

function _M:callWithinStack(instance, route, req, method)

    local params = route.parameters
    local context = app:ctx()
    if not rawget(context, 'req') then
        context.req = req
    end
    req._actionName = method
    req._ctlerName = instance.__cls
    
    local pl = app:make('pipeline', app)
    local bars = instance.bars

    pl:send(context):through(bars):check(filterBar):deal(function()
        local action, ret

        action = instance.callAction
        if action then
            ret = action(instance, context, method, route:getParams())
        end

        if not ret then
            action = instance[method]
            if not action then
                error('method:' .. method .. ' not exists')
            end

            ret = action(instance, context, unpack(params))
        end

        if ret then
            context:output(ret)
        end
    end, instance, method)
end

function _M:makeCtler(ctler, route)
 
    local router = app.router
 
    if not app:bound(ctler) then
        app:single(ctler)
    end
    
    -- local ctlerBag = app:getBag(ctler)
    -- local instance = app:create(ctler, ctlerBag, nil, route.action.bar)
    local instance = app:make(ctler, route.action.bar)
    return instance
end

return _M

