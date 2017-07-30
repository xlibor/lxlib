
local lx, _M, mt = oo{
    _cls_    = '',
}

local app, lf, tb, str, new = lx.kit()

function _M:new(entity)

    local this = {
        entity = entity
    }

    return oo(this, mt)
end

function _M:_get_(key)

    return self.entity[key]
end

function _M:get(key)

    if self:__has(key) then
        local method = self[key]

        return method(self)
    end
end

return _M

