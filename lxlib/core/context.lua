
local lx, _M, mt = oo{
    _cls_ = '',
}

local app, lf, tb, str = lx.kit()

function _M:new()
    
    local this = {
        instances    = {},
        needOvers    = {},
        needDives    = {},
        drivers        = {},
        sharedData    = {}
    }
    
    oo(this, mt)

    return this
end

function _M:ctor()

end

function _M:get(nick)

    return self.instances[nick]
end

function _M:set(nick, obj)

    self.instances[nick] = obj
end

function _M:share(key, value)

    local keys = lf.isTbl(key) and key or {key = value}
    for key, value in pairs(keys) do
        self.sharedData[key] = value
    end
    
    return value
end

function _M:shared(key, default)

    return tb.get(self.sharedData, key, default)
end

function _M:getShared()

    return self.sharedData
end

function _M.d__:id()

    return lf.guid()
end

return _M

