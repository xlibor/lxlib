
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'abstractPaginator'
}

local app, lf, tb, str, new = lx.kit()

local ceil = math.ceil
local UrlWindow = lx.use('urlWindow')
local static, viewFactory

function _M._init_(this)

    static = this.static
    viewFactory = app.view
end

function _M:ctor(items, total, perPage, currentPage, options)

    if not items then
        return
    end
    
    options = options or {}
    for key, value in pairs(options) do
        self[key] = value
    end
    self._total = total
    self._perPage = perPage
    self._lastPage = tonumber(ceil(total / perPage))
    self.path = self.path ~= '/' and str.rtrim(self.path, '/') or self.path

    self._currentPage = self:setCurrentPage(currentPage, self._lastPage)

    self.items = lf.isA(items, 'col') and items or lx.col(items)
end

function _M.__:setCurrentPage(currentPage, lastPage)

    currentPage = currentPage or static.resolveCurrentPage()

    return self:isValidPageNumber(currentPage) and tonumber(currentPage) or 1
end

function _M:nextPageUrl()

    if self:lastPage() > self:currentPage() then
        
        return self:url(self:currentPage() + 1)
    end
end

function _M:hasMorePages()

    return self:currentPage() < self:lastPage()
end

function _M:total()

    return self._total
end

function _M:lastPage()

    return self._lastPage
end

function _M:links(view)

    return self:render(view)
end

function _M:render(view)

    local window = UrlWindow.make(self)
    local first, last, slider = window.first, window.last, window.slider
    local elements = {
        first or true,
        lf.isTbl(slider) and '...' or true,
        slider or true,
        lf.isTbl(last) and '...' or true,
        last or true
    }

    viewFactory:fill(
        view or static.defaultView, {
        paginator = self,
        elements = elements
    })

end

function _M:toArr()

    return {
        total = self:total(),
        per_page = self:perPage(),
        current_page = self:currentPage(),
        last_page = self:lastPage(),
        next_page_url = self:nextPageUrl(),
        prev_page_url = self:previousPageUrl(),
        from = self:firstItem(),
        to = self:lastItem(),
        data = self.items:toArr()
    }
end

return _M

