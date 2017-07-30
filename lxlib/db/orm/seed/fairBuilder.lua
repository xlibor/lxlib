
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str, new = lx.kit()
local Model = lx.use('model')

function _M:new()

    local this = {
        definitions = nil,
        class = nil,
        name = 'default',
        amount = 1,
        faker = nil
    }
    
    return oo(this, mt)
end

function _M:ctor(class, name, definitions, faker)

    class = lf.needCls(class)
    self.name = name
    self.class = class
    self.faker = faker
    self.definitions = definitions
end

function _M:times(amount)

    self.amount = amount
    
    return self
end

function _M:create(attrs)

    attrs = attrs or {}
    local results = self:make(attrs)
    if self.amount == 1 then
        results:save()
    else
        for _, result in results:kv() do
            result:save()
        end
    end
    
    return results
end

function _M:make(attrs)

    attrs = attrs or {}
    if self.amount == 1 then
        
        return self:makeInstance(attrs)
    end
    
    return lx.col(tb.map(tb.range(1, self.amount), function()
        return self:makeInstance(attrs)
    end))
end

function _M.__:makeInstance(attrs)

    attrs = attrs or {}

    return Model.unguardOn(function()
        local t = tb.gain(self.definitions, self.class, self.name)
        if not t then
            lx.throw('invalidArgumentException', fmt(
                "Unable to locate fair with name [%s] [%s]",
                self.name, self.class)
            )
        end
        local definition = lf.call(t, self.faker, attrs)
        local evaluated = self:callClosureAttrs(tb.merge(definition, attrs))
        
        return new(self.class, evaluated)
    end)
end

function _M.__:callClosureAttrs(attrs)

    local attr
    for _, attr in pairs(attrs) do
        attr = lf.isFunc(attr) and attr(attrs) or attr
    end
    
    return attrs
end

return _M

