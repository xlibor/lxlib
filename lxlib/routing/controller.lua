
local lx, _M, mt = oo{ 
    _cls_    = '',
}

local app, lf, tb, str, new = lx.kit()
local router

function _M._init_(this)

    if not app:isCmdMode() then
        router = app.router
    end
end

function _M:new(bars)

    local this = {
        bars = bars or lx.col(),
        barOptions = {}
    }

    oo(this, mt)

    return this
end

function _M:setBar(name, option)
    
    if lf.isFunc(name) then
        self.bars:set(str.random(8), name)
        return
    end
    
    local router = router or app.router
    bar = router:getRouteBar(name)

    if bar then
        local barType = type(bar)
        if barType == 'string' then

            self.bars:set(bar, bar)
            name = bar
        elseif barType == 'table' then

            for _, v in pairs(bar) do
                self.bars:set(v, v)
            end
        end
    else
        local barName, barValue = router:parseBarParams(name)
        self.bars:set(barName, barValue)
        name = barName
    end

    if option then
        local k, v = next(option)
        v = lf.needList(v)
        v = tb.flip(v, true)
        option[k] = v
        self.barOptions[name] = option
    end
end

function _M:getBars()
    
    return self.bars
end

function _M:doer(doerName, ...)

    if not self.doers then
        self.doers = {}
    end

    local doerCls = self:resolveDoer(doerName)
    local doer = self.doers[doerCls]
    if doer then
        return doer
    end

    doer = new(doerCls, ...)
    self.doers[doerCls] = doer

    return doer
end

function _M:resolveDoer(doerCls)

    if not doerCls then
        local clsName = str.match(self.__cls, '%.(%w+)$')
        doerCls = '.app.http.doer.' .. clsName
    end

    return doerCls
end

return _M

