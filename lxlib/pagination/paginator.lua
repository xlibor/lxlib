
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'abstractPaginator'
}

local app, lf, tb, str = lx.kit()

local static, viewFactory

function _M._init_(this)

    static = this.static
    viewFactory = app.view
end

function _M:ctor(items, perPage, currentPage, options)

    options = options or {}
    for key, value in pairs(options) do
        self[key] = value
    end
    self.perPage = perPage
    self._currentPage = self:setCurrentPage(currentPage)
    self.path = self.path ~= '/' and str.rtrim(self.path, '/') or self.path
    self.items = lf.isA(items, 'col') and items or lx.col(items)
    self:checkForMorePages()
    self.hasMore = nil
end

function _M.__:setCurrentPage(currentPage)

    currentPage = currentPage or static.resolveCurrentPage()
    
    return self:isValidPageNumber(currentPage) and tonumber(currentPage) or 1
end

function _M.__:checkForMorePages()

    self.hasMore = #self.items > self.perPage
    self.items = self.items:slice(0, self.perPage)
end

function _M:nextPageUrl()

    if self:hasMorePages() then
        
        return self:url(self:currentPage() + 1)
    end
end

function _M:hasMorePagesWhen(value)

    value = lf.needTrue(value)
    self.hasMore = value
    
    return self
end

function _M:hasMorePages()

    return self.hasMore
end

function _M:links(view)

    return self:render(view)
end

function _M:render(view)

    viewFactory():fill(
        view or static.defaultSimpleView,
        {paginator = self}
    )
end

function _M:toArr()

    return {
        per_page = self:perPage(),
        current_page = self:currentPage(),
        next_page_url = self:nextPageUrl(),
        prev_page_url = self:previousPageUrl(),
        from = self:firstItem(),
        to = self:lastItem(),
        data = self.items:toArr()
    }
end

return _M

