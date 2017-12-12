
local lx, _M, mt = oo{
    _cls_           = '',
    _bond_          = {
        'htmlable', 'eachable', 'jsonable', 'packable'
    },
    _static_        = {
        _currentPathResolver = nil,
        _currentPageResolver = nil,
        defaultView = 'pagination:default',
        defaultSimpleView = 'pagination:simple-default'
    }
}

local app, lf, tb, str = lx.kit()

local static

function _M._init_(this)

    static = this.static
end

function _M:new()

    local this = {
        items = nil,
        _perPage = nil,
        _currentPage = nil,
        path = '/',
        query = {},
        _fragment = nil,
        pageName = 'page'
    }
    
    return oo(this, mt)
end

function _M.__:isValidPageNumber(page)

    return lf.isInt(page) and page >= 1
end

function _M:getUrlRange(start, last)

    local urls = {}
    for page = start, last do
        urls[page] = self:url(page)
    end
    
    return urls
end

function _M:url(page)

    if page <= 0 then
        page = 1
    end
    
    local parameters = {[self.pageName] = page}
    if next(self.query) then
        parameters = tb.merge(self.query, parameters)
    end

    return self.path .. (str.has(self.path, '?') and '&' or '?')
        .. lf.httpBuildQuery(parameters, '', '&')
        .. self:buildFragment()
end

function _M:previousPageUrl()

    if self:currentPage() > 1 then
        
        return self:url(self:currentPage() - 1)
    end
end

function _M:fragment(fragment)

    if not fragment then
        
        return self._fragment
    end
    self._fragment = fragment
    
    return self
end

function _M:appends(key, value)
    
    if lf.isTbl(key) then
        
        return self:appendArray(key)
    end
    
    return self:addQuery(key, value)
end

function _M.__:appendArray(keys)

    for key, value in pairs(keys) do
        self:addQuery(key, value)
    end
    
    return self
end

function _M:addQuery(key, value)

    if key ~= self.pageName then
        self.query[key] = value
    end
    
    return self
end

function _M.__:buildFragment()

    return self._fragment and '#' .. self._fragment or ''
end

function _M:firstItem()

    if self.items:count() == 0 then
        
        return
    end
    
    return (self._currentPage - 1) * self._perPage + 1
end

function _M:lastItem()

    if self.items:count() == 0 then
        
        return
    end
    
    return self:firstItem() + self:count() - 1
end

function _M:perPage()

    return self._perPage
end

function _M:onFirstPage()

    return self:currentPage() <= 1
end

function _M:currentPage()

    return self._currentPage
end

function _M:hasPages()

    return not (self:currentPage() == 1 and not self:hasMorePages())
end

function _M.s__.resolveCurrentPath(default)

    default = default or '/'
    if static._currentPathResolver then
        
        return lf.call(static._currentPathResolver)
    end
    
    return default
end

function _M.s__.currentPathResolver(resolver)

    static._currentPathResolver = resolver
end

function _M.s__.resolveCurrentPage(pageName, default)

    default = default or 1
    pageName = pageName or 'page'

    if static._currentPageResolver then

        return lf.call(static._currentPageResolver, pageName)
    end
    
    return default
end

function _M.s__.currentPageResolver(resolver)

    static._currentPageResolver = resolver
end

function _M.s__.setDefaultView(view)

    static.defaultView = view
end

function _M.s__.setDefaultSimpleView(view)

    static.defaultSimpleView = view
end

function _M:getPageName()

    return self.pageName
end

function _M:setPageName(name)

    self.pageName = name
    
    return self
end

function _M:setPath(path)

    self.path = path
    
    return self
end

function _M:toEach()

    return pairs(self.items:all())
end

function _M:isEmpty()

    return self.items:isEmpty()
end

function _M:count()

    return self.items:count()
end

function _M:getCol()

    return self.items
end

function _M:setCol(items)

    self.items = items
    
    return self
end

function _M:toHtml()

    return tostring(self:render())
end

function _M:_run_(method)

    return 'getCollection'
end

function _M:toStr()

    return tostring(self:render())
end

function _M:toJson(options)

    return lf.jsen(self:toArr())
end

function _M:pack(packer)

    return self
end

function _M:unpack(data, packer)

    for k, v in pairs(data) do
        self[k] = v
    end
end

return _M

