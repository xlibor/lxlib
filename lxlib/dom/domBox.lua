
local lx, _M = oo{
    _cls_ = '',
    _ext_ = 'box'
}

local app, lf, tb, str = lx.kit()

function _M:wrap()

    app:wrap('lxlib.dom.base.htmlparser',
        'lxlib.dom.base.htmlparserWrapper'
    )
    app:wrap('lxlib.dom.base.htmlparser.ElementNode',
        'lxlib.dom.base.elementNodeWrapper'
    )
end

function _M:reg()

    app:bindFrom('lxlib.dom', {
        'domNode', 'domDocument', 'domElement'
    })
end

function _M:boot()

end

return _M

