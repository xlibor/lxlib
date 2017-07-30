
local lx, _M, mt = oo{
    _cls_     = '',
}

local lf = lx.f

function _M:new()

    local this = {
    }

    return oo(this, mt)
end

function _M:ctor()

    self:init()
end

function _M:init()

    self.beginTime = lf.now(true)
    self.original = self.beginTime
    self.pauseTime = 0
    self.pauseCost = 0
end

function _M:start()

    self:init()
end

function _M:reset()

    self.beginTime = lf.now(true)
end

function _M:past()

    local t = lf.now(true)

    local pastTime = t - self.beginTime
    self.beginTime = t

    return pastTime
end

function _M:pause()

    self.pauseTime = lf.now(true)
end

function _M:continue()

    local t = lf.now(true)
    self.pauseCost = self.pauseCost + t - self.pauseTime
    self.beginTime = t
end

function _M:pastTotal()

    local t = lf.now(true)
    local total = t - self.original - self.pauseCost

    return total
end

return _M

