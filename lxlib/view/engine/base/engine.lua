
local _M = {
    _cls_ = ''
}

local mt = { __index = _M }

local lx = require('lxlib')
local app = lx.app()

function _M:new(engine)

    local this = {
        engine = engine,
        cache = app:make('view.'..engine..'.cache')
    }

    setmetatable(this, mt)

    return this
end

function _M:render(view, data, namespace, env)
    
    local tpl = self.cache:getObj(view)

    if not tpl then
        local engine = self.engine
        tpl = app:make('view.'..engine..'.tpl', engine, view, namespace)
        self.cache:setObj(view, tpl)
        return tpl:render(data, false, env)
    else
        return tpl:render(data, true, env)
    end
end

return _M

