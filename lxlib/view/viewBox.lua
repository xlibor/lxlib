
local lx, _M = oo{
    _cls_ = '',
    _ext_ = 'box'
}

local app, lf, tb, str, new = lx.kit()

function _M:reg()

    self:regDepends()
    self:regViewFactory()
    self:regViewEngine()
    self:regViewFinder()

    self:regExcp()

end

function _M:regViewFactory()

    local factory = 'lxlib.view.factory'

    app:single('view', factory, function()
        local finder = app:make('view.finder')
        local resolver = app:make('view.engine.resolver')
        local defaultEngine = app:conf('view.engine')

        return new(factory, resolver, finder, defaultEngine)
    end)

    app:bind('view.doer', 'lxlib.view.view')
end

function _M:regViewFinder()

    local finder = 'lxlib.view.finder'

    app:bind('view.finder', finder, function()

        return new(finder,
            app:get('files'),
            app:conf('view.paths'),
            app:conf('view.extension')
        )
    end)
end

function _M:regViewEngine()

    local engineResolver = 'lxlib.view.engine.resolver'

    app:single('view.engine.resolver', engineResolver, function()

        local resolver = new(engineResolver)
        for _, name in ipairs{'twig', 'blade'} do
            resolver:reg(name, function()
                return app:make('view.'..name..'.engine', name)
            end)
        end

        return resolver
    end)
end

function _M:regExcp()

    app:bindFrom('lxlib.view.excp', {
        'viewException', 'viewNotExistsException', 'viewParseException',
        'viewCompileException', 'viewPreloadException', 'viewRenderException'
    })

end

function _M:regDepends()
    
    local basePath = 'lxlib.view.engine.base'
    local twigPath = 'lxlib.view.engine.twig'
    local bladePath = 'lxlib.view.engine.blade'
    local twigEngine = 'view.twig.'
    local bladeEngine = 'view.blade.'

    app:bindFrom(basePath, {
        'tpl', 'loader', 'compiler', 'env',
    }, {prefix = twigEngine})

    app:bindFrom(twigPath, {
        'engine', 'parser'
    }, {prefix = twigEngine})

    app:single(twigEngine..'config',    twigPath .. '.config')
    app:single(twigEngine..'cache',     basePath .. '.cache')
    app:single(twigEngine..'custom',    basePath .. '.custom')

    app:bindFrom(basePath, {
        'engine', 'tpl', 'loader', 'compiler', 'env'
    }, {prefix = bladeEngine})

    app:bindFrom(bladePath, {
        'parser'
    }, {prefix = bladeEngine})

    app:single(bladeEngine..'config',    bladePath .. '.config')
    app:single(bladeEngine..'cache',     basePath .. '.cache')
    app:single(bladeEngine..'custom',    basePath .. '.custom')
    
    app:single('view.engine.base.func', 'lxlib.view.engine.base.func', '')
    app:bind('view.engine.base.filter', 'lxlib.view.engine.base.filter')
    app:single('lxlib.view.bar.shareErrorsFromSession')
end

function _M:boot()

end

return _M

