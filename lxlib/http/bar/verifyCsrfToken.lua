
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str, new = lx.kit()
local throw = lx.throw

function _M:new(encrypter)

    local this = {
        encrypter = encrypter,
        except = {}
    }

    return oo(this, mt)
end

function _M:handle(ctx, next)

    local req = ctx.req
    if self:isReading(req) or self:runningUnitTests() or
        self:shouldPassThrough(req) or self:tokensMatch(req) then

        next(ctx)

        self:addCookieToResponse(req, ctx.resp)
        return
    end

    throw('tokenMismatchException')
end

function _M.__:shouldPassThrough(request)

    for _, except in ipairs(self.except) do
        if except ~= '/' then
            except = str.trim(except, '/')
        end

        if request:is(except) then
            return true
        end
    end

    return false
end

function _M.__:runningUnitTests()

    return app:runningInConsole() and app:runningUnitTests()
end

function _M.__:tokensMatch(request)

    local sessionToken = request.session:token()

    local token = request:input('_token') or request:header('x-csrf-token')

    local header = request:header('x-xsrf-token')
    if (not token) and header then
        token = self.encrypter:decrypt(header)
    end

    if not lf.isStr(sessionToken) or not lf.isStr(token) then
        return false
    end

    return sessionToken == token
end

function _M.__:addCookieToResponse(request, response)

    local config = app:conf('session')

    response.headers:setCookie(
        new('simpleCookie',
            'XSRF-TOKEN', request.session:token(), lf.time() + 60 * config['lifetime'],
            config['path'], config['domain'], config['secure'], false
        )
    )
end

function _M.__:isReading(request)

    return tb.inList({'head', 'get', 'options'}, request.method)
end

return _M

