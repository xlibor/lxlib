
local lx, _M, mt = oo{ 
    _cls_ = '',
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
    }

    return oo(this, mt)
end

function _M:handle(ctx, goon)

    goon(ctx)

    local headers = ctx.resp.headers
    local ckj = ctx:get('cookie') or app:get('cookie')
    local cookies = ckj:getQueuedCookies()

    if next(cookies) then

        for k, v in pairs(cookies) do

            headers:setCookie(v)
        end
    end
end

return _M

