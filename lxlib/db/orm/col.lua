
local lx, _M = oo{ 
    _cls_ = '',
    _ext_ = 'col',

}

local app, lf, tb, str = lx.kit()

function _M:ctor(models)

    self:useList()
    self:init(models)
    self:itemable()
    self:setDefault('')
end

function _M:load(...)

    local relations = lf.needArgs(...)
    if self:count() > 0 then
        local query = self:first():newQuery():with(relations)

        self.items = query:eagerLoadRelations(self.items)
    end

    return self
end

function _M:contains(key, value)

    if key and value then
        
        return self:__super('contains', key, value)
    end
    if lf.isFunc(key) then
        
        return self:__super('contains', key)
    end

    key = lf.isA(key, 'model') and key:getKey() or key

    return self:__super('contains', function(model)

        return lf.eq(model:getKey(), key)
    end)
end

function _M:pack(packer)

    local models = {}
    for i, model in ipairs(self:all()) do
        tapd(models, model)
    end

    return {}, {models}
end

function _M:unpack(models, packer)

    -- for i, model in ipairs(models) do
    --     self:set(i, packer:unpack(model))
    -- end
end

return _M

