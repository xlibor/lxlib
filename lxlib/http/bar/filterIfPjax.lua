
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str, new = lx.kit()
local abort = lx.h.abort

function _M:new()

    local this = {
    }

    return oo(this, mt)
end

function _M:handle(ctx, next)

    next(ctx)

    local req, resp = ctx.req, ctx.resp

    if (not req.pjax) or resp:isRedirection() then

        return
    end

    self:filterResponse(resp, 'body')
        :setUriHeader(resp, req)
        :setVersionHeader(resp, req)

end

function _M:filterResponse(resp, container)

    local title = self:makeTitle(resp)

    local body = self:fetchContainer(resp, container)

    resp:setContent(title .. body)

    return self
end

function _M:makeTitle(resp)

    local content = resp:getContent()
    local m = str.rematch(content, [[<title>([^<]+)</title>]])
    if not m then
        return ''
    end

    return '<title>' .. m[1] .. '</title>'
end

function _M:fetchContainer(resp, container)

    local content = resp:getContent()
    local m = str.rematch(content, [[(?:<body[^>]*>)(.*)<\/body>]], 'isU')

    if not m or #m == 0 then
        abort(422)
    end

    return m[1]
end

function _M:setUriHeader(resp, req)

    resp:header('X-PJAX-URL', req.url)

    return self
end

function _M:setVersionHeader(resp, req)

    return self
end

return _M

