
local _M = { 
    _cls_ = ''
}

local mt = { __index = _M }

local lx = require('lxlib')
local app, lf, tb, str, new = lx.kit()
local try = lx.try

function _M:new()

    local this = {
        router = app.router,
        loaders = {
            'lxlib.core.load.loadConfig',
            'lxlib.core.load.regBoxes',
            'lxlib.core.load.bootBoxes',
            'lxlib.core.load.regFaces'
        }
    }

    setmetatable(this, mt)

    return this
end

function _M:handle()

    local response, ctx

    try(function()

        ctx = app:prepare()
        self:load()
        ctx = ctx or app:ctx()
        self:bindContext(ctx)
        self:sendRequestThroughRouter(ctx.req, ctx)

        response = ctx.resp
        self:sendResponse(response)
    end)
    :catch(function(e)
        if not ctx then
            ctx = app:prepare(true)
            self:bindContext(ctx)
        end
        
        self:reportException(e)
        self:renderException(e, ctx)

        self:sendResponse(ctx.resp)
    end)
    :catch(function(e)
        e = new('fatalErrorException', e)
        self:reportException(e)
        self:renderException(e, ctx)
        
        self:sendResponse(ctx.resp)
    end)
    :catch(function(e)
        -- echo('error:' .. e.msg)
    end)
    :final(function(e, caught)
        if caught then
        end
        if ctx then
            response = ctx.resp
        end
    end):run()

    return response
end

function _M:sendResponse(response)

    if response then 
        response:send()
        local ctx = app:ctx()
        
        self:over(ctx)
        self:dive(ctx)
    else
        echo('no response')
    end

end

function _M:initBars()

    self:initGlobalBars()

    local router = self.router
     
    router:setBarGroups(self.barGroup)
 
    router:setBars(self.routeBars)

end

function _M:initGlobalBars()

    local bars = lx.n.obj()
    local nick, bar
    local vt

    for k, v in pairs(self.bars) do
        vt = type(v)
        if vt == 'string' then
            nick, bar = v, v
        elseif vt == 'table' then
            nick, bar = v[1], v[2]    
        else
            error('unsupported bar def type')
        end
 
        bars:set(nick, bar)
    end

    self.globalBars = bars
end

function _M:load()
    
    if not app.loaded then
        app:loadWith(self.loaders)
    end
end

function _M:bindContext(ctx)

    local req, resp = new 'request', new 'response'
    ctx.req = req; ctx.resp = resp
    ctx.bars = {}
end

function _M:sendRequestThroughRouter(req, ctx)
    
    local pl = app:make('pipeline', app)

    pl:send(ctx):through(self.globalBars):deal(function()
        self:dispatchToRouter(req)
    end)
end

function _M:dispatchToRouter(req)

    self.router:dispatch(req)
end

function _M:reportException(e)

    app:get('exception.handler'):report(e)
end

function _M:renderException(e, ctx)
    
    local resp = ctx.resp
    if resp:__is('redirectResponse') then
        ctx.resp = new 'response'
    end

    app:get('exception.handler'):render(e, ctx)
end

function _M:over(ctx)

    ctx = ctx or app:ctx()

    for _, bar in pairs(ctx.bars) do
        if bar.over then
            bar:over(ctx)
        end
    end

    app:over(ctx)
end

function _M:dive(ctx)

    ctx = ctx or app:ctx()

    ngx.eof()

    for _, bar in pairs(ctx.bars) do
        if bar.dive then
            bar:dive(ctx)
        end
    end

    app:dive(ctx)
end

return _M

