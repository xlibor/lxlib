
local lx, _M, mt = oo{
    _cls_   = '',
    _bond_ = 'renderable'
}

local app, lf, tb, str = lx.kit()

function _M:new(factory, engine, view, data, namespace)

    local this = {
        factory = factory,
        engine    = engine,
        view    = view,
        data    = data or {},
        namespace = namespace
    }

    return oo(this, mt)
end

function _M:render(env)
    
    local name = self.view

    local data = self:collectData()

    return self.engine:render(name, data, self.namespace, env)
end

function _M:collectData()

    local data = self.data

    return data
end

function _M:with(key, value)

    local vt = type(key)

    if vt == 'table' then
        for k, v in pairs(key) do
            self.data[k] = v
        end
    else
        self.data[key] = value
    end
end

return _M

