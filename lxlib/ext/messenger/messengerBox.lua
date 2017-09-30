
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'box'
}

local app, lf, tb, str = lx.kit()

function _M:boot()

    local dir = lx.getPath(true)
    
    if app:runningInConsole() then
        self:publish(
            {[dir .. '/conf/*'] = lx.dir('conf')},
            'lxlib-messenger-conf')
        self:publish(
            {[dir .. '/shift/*'] = lx.dir('db', 'shfit')},
            'lxlib-messenger-shift')
    end
    
    Models = lx.use('models')
    Models.load('messenger')
end

function _M:reg()

    app:bindFrom('lxlib.ext.messenger.model', {
        'message', 'participant', 'thread'
    }, {prefix = 'messenger.'})

    app:bind('messenger.messagable', 'lxlib.ext.messenger.messagable')
end

return _M

