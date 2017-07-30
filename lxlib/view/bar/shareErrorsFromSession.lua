
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str, new = lx.kit()

local view

function _M._init_()

    view = app.view
end

function _M:new()

    local this = {
    }

    return oo(this, mt)
end

function _M:handle(ctx, next)

    local request = ctx.req
    local errors = request.session:get('errors') or new('viewErrorBag')

    local msgs
    if errors.default then
        msgs = errors.default.msgs
        errors = app:restore('msgBag', msgs)
    else
        msgs = errors.bags.default.msgs
        errors = app:restore('msgBag', msgs)
    end

    view:share(
        {errors = errors}, ctx
    )
    
    return next(ctx)
end

return _M

