
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'box'
}

local app, lf, tb, str = lx.kit()

function _M:boot()

    local Paginator = lx.use('paginator')
 
    Paginator.currentPathResolver(function()

        return app:get('request').uri
    end)

    Paginator.currentPageResolver(function(pageName)
        page = app:get('request'):input(pageName)
        page = tonumber(page)

        if page and page >= 1 then
            
            return page
        end
        
        return 1
    end)

    local dir = lx.getPath(true)
    self:loadViewsFrom(dir .. '/res/view', 'pagination')
    if app:runningInConsole() then
        self:publish(
            {[dir .. '/res/view/*'] = lx.dir('res', 'view/vendor/pagination')},
            'lxlib-pagination')
    end
end

function _M:reg()

    app:bindFrom('lxlib.pagination', {
        'abstractPaginator', 'lengthAwarePaginator',
        'paginator', 'urlWindow'
    })

end

return _M

