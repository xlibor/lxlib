
local lx, _M = oo{ 
    _cls_ = '',
    _ext_ = 'box'
}

local app = lx.app()

function _M:reg()

    self:regDepends()

    app:single('cache', 'lxlib.cache.cacheManager')

    app:single('cache.store', function()
        local cache = app.cache

        return cache:driver()
    end)

    app:bind('cache.lock', 'lxlib.cache.cacheLock')
end

function _M:boot()

    app:resolving('commander' ,function(cmder)

        cmder:group({ns = 'lxlib.cache.cmd', lib = false, app = true}, function()

            cmder:add('cache/table', 'cacheTableCmd@make')
        end)
    end)

end

function _M:regDepends()
    
    app:bind('cache.doer',          'lxlib.cache.cacheDoer')
    app:bind('cache.taggedDoer',    'lxlib.cache.taggedCache')
    app:bind('cache.tagSet',        'lxlib.cache.tagSet')
    
    app:bond('cacheStoreBond', 'lxlib.cache.bond.store')
end

return _M

