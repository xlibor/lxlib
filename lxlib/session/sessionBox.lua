
local lx, _M = oo{ 
    _cls_ = '',
    _ext_ = 'box'
}

local app = lx.app()

function _M:reg()

    app:bond('sessionBaseBond',     'lxlib.session.bond.base')
    app:bond('sessionHandlerBond',  'lxlib.session.bond.sessionHandler')
    app:bond('sessionBond',         'lxlib.session.bond.session')
 
    self:regDepends()
    app:single('session.manager', 'lxlib.session.manager')

    app:keep('session.store', function()
        local manager = app:get('session.manager')

        return manager:driver()
    end)

    app:bind('session', function()

        return app:get('session.store')
    end)

    app:single('lxlib.session.bar.startSession')
end

function _M.__:regDepends()
    
    app:bind('session.commonStore',         'lxlib.session.store')
    app:bind('tokenMismatchException',      'lxlib.session.excp.tokenMismatchException')
end

function _M:boot()

    app:resolving('commander' ,function(cmder)

        cmder:group({ns = 'lxlib.session.cmd', lib = false, app = true}, function()

            cmder:add('session/table', 'sessionTableCmd@make')
        end)
    end)
end

return _M

