
local _M = {
    _cls_    = ''
}

local mt = { __index = _M }

local lx = require('lxlib').load(_M)
local app, lf, tb, str = lx.kit()
local try, throw = lx.try, lx.throw

function _M:new(engines, finder, default)

    local this = {
        engines     = engines,
        finder         = finder,
        gatherers     = {},
        touchers    = {},
        default     = default or 'blade'
    }

    setmetatable(this, mt)

    return this
end

function _M:get(view, data, defedEngine)

    local view = self:make(view, data, defedEngine)

    return view:render()
end

function _M:fill(view, data, defedEngine)

    local view = self:make(view, data, defedEngine)
    local env = app:ctx():get('viewEnv')

    if env then
        return view:render(env)
    else
        error('no tpl or env inited.')
    end
end

function _M:make(view, data, defedEngine)

    local engine
    local namespace

    if not defedEngine then
        view, defedEngine, namespace = self:getInfoFromPath(view)
    end

    if namespace then
        defedEngine = self.finder:getEngineFromNamespace(namespace)
    end

    if defedEngine and defedEngine ~= self.default then
        engine = self:resolve(defedEngine)
    else
        engine = self.engine
    end

    data = self:prepareData(data)

    local view = app:make('view.doer', self, engine, view, data, namespace)

    return view
end

function _M:addNamespace(namespace, path, engine)

    self.finder:addNamespace(namespace, path, engine)
end

function _M.__:getInfoFromPath(path)

    local engine, namespace

    local i, j = str.find(path, '%s')

    if i then
        return path
    end

    if str.find(path, '@') then
        engine, path = str.div(path, '@')
    end

    if str.find(path, ':') then
        namespace, path = str.div(path, ':')
    end

    return path, engine, namespace
end

function _M.__:prepareData(data)

    local vt = type(data)

    data = data or {}
    
    if data.__cls then
        if data:__is 'arrable' then
            data = data:toArr()
        end
    end

    local ctx = app:ctx()
    local shared = ctx:getViewShared()
    if next(shared) then
        data = tb.mergeDict(data, shared)
    end

    return data
end

function _M:share(data, ctx)

    if not ctx then
        ctx = app:ctx()
    end

    ctx:viewShare(data)
end

function _M:gather(views, handler, useTouch)

    views = lf.needList(views)

    for _, view in ipairs(views) do
        self.gatherers[view] = handler
        if useTouch then
            self.touchers[view] = handler
        end
    end
end

function _M:touch(views, handler)

    views = lf.needList(views)

    for _, view in ipairs(views) do
        self.touchers[view] = handler
    end
end

function _M:runGather(context, view, tpl)

    local gatherer = self.gatherers[view]

    if gatherer then
        lx.call(gatherer, 'gather', context, view, tpl)
    end
end

function _M:runTouch(context, view, tpl)

    local toucher = self.touchers[view]

    if toucher then
        lx.call(toucher, 'touch', context, view, tpl)
    end
end

function _M:exists(view)

    local ok = 
    try(function()

        return self.finder:find(view)
    end)
    :catch(function(e)
        return false
    end):run()

    return ok
end

function _M:resolve(engine)

    return self.engines:resolve(engine)
end

function _M.d__:engine()

    local default = self.default

    return self.engines:resolve(default)
end

function _M:__call(...)

    local view = self:make(...)

    return view:render()
end

return _M

