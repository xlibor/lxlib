
local _M = {
    _cls_ = '',
    _ext_ = 'box'
}

local mt = { __index = _M }

local lx = require('lxlib')
local app = lx.app()

function _M:ctor()

end

function _M:reg()

    app:bind('carrier.doer', 'lxlib.carrier.carrierDoer')

end

function _M:boot()
     
    app:resolving('commander' ,function(cmder)

        cmder:group({ns = 'lxlib.carrier', lib = true, app = true}, function()
            cmder:add('carrier/install|pm/inst', 'carrierCmd@install')
            cmder:add('carrier/reset|pm/reset', 'carrierCmd@reset')
            cmder:add('carrier/update|pm/update', 'carrierCmd@update')
        end)
    end)
end

return _M

