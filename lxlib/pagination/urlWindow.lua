
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

function _M:new(paginator)

    local this = {
        paginator = paginator
    }
    
    return oo(this, mt)
end

function _M.make(paginator, onEachSide)

    onEachSide = onEachSide or 3
    
    return app('urlWindow', paginator):get(onEachSide)
end

function _M:get(onEachSide)

    onEachSide = onEachSide or 3
    if self.paginator:lastPage() < onEachSide * 2 + 6 then
        
        return self:getSmallSlider()
    end
    
    return self:getUrlSlider(onEachSide)
end

function _M.__:getSmallSlider()

    return {first = self.paginator:getUrlRange(1, self:lastPage()),
        slider = nil, last = nil
    }
end

function _M.__:getUrlSlider(onEachSide)

    local window = onEachSide * 2
    if not self:hasPages() then
        
        return {first = nil, slider = nil, last = nil}
    end
    
    if self:currentPage() <= window then
        
        return self:getSliderTooCloseToBeginning(window)
    elseif self:currentPage() > self:lastPage() - window then
        
        return self:getSliderTooCloseToEnding(window)
    end
    
    
    return self:getFullSlider(onEachSide)
end

function _M.__:getSliderTooCloseToBeginning(window)

    return {
        first = self.paginator:getUrlRange(1, window + 2),
        slider = nil, last = self:getFinish()
    }
end

function _M.__:getSliderTooCloseToEnding(window)

    local last = self.paginator:getUrlRange(
        self:lastPage() - (window + 2), self:lastPage()
    )
    
    return {first = self:getStart(), slider = nil, last = last}
end

function _M.__:getFullSlider(onEachSide)

    return {
        first = self:getStart(),
        slider = self:getAdjacentUrlRange(onEachSide),
        last = self:getFinish()
    }
end

function _M:getAdjacentUrlRange(onEachSide)

    return self.paginator:getUrlRange(
        self:currentPage() - onEachSide,
        self:currentPage() + onEachSide
    )
end

function _M:getStart()

    return self.paginator:getUrlRange(1, 2)
end

function _M:getFinish()

    return self.paginator:getUrlRange(
        self:lastPage() - 1, self:lastPage()
    )
end

function _M:hasPages()

    return self.paginator:lastPage() > 1
end

function _M.__:currentPage()

    return self.paginator:currentPage()
end

function _M.__:lastPage()

    return self.paginator:lastPage()
end

return _M

