
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'box'
}

local app, lf, tb, str, new = lx.kit()

function _M:reg()

    self:regDepends()
    self:regLoader()

    local translator = 'lxlib.translation.translator'
    app:single('translator', translator, function()

        local loader = app:get('translation.loader')
        local locale = app:conf('app.locale')
        local trans = new(translator, loader, locale)
        trans:setFallback(app:conf('app.fallbackLocale'))

        return trans
    end)
end

function _M.__:regLoader()

    app:single('translation.loader', function()

        return new('lxlib.translation.loader.file', app.files, app.langPath)
    end)
end

function _M.__:regDepends()

    app:bond('translationLoaderBond',   'lxlib.translation.bond.loader')
    app:bond('translatorBond',          'lxlib.translation.bond.translator')
end

function _M:boot()

end

return _M

