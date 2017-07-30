
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

local router

function _M._init_()

    if not app:isCmdMode() then
        router = app:get('router')
    end
end

function _M:new()

    local this = {}

    return oo(this, mt)
end

function _M:handle(context, next)

    local req = context.req
    local route = req:getRoute()
    local router = router or app:get('router')

    router:replaceBinding(route)

    next(context)
end

return _M

