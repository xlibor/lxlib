
local lx, _M = oo{
    _cls_ = '',
    _ext_ = 'box'
}

local app, lf, tb, str = lx.kit()
local boxPath = 'lxlib.ext.flash.'

function _M:reg()

    app:single('flash', boxPath .. 'flashNotifier')
end

function _M:boot()

    local dir = lx.getPath(true)
    self:loadViewsFrom(dir .. '/res/view', 'flash')
    
    if app:runningInConsole() then
        self:publish(
            {[dir .. '/res/view/*'] = lx.dir('res', 'view/vendor/flash')},
            'lxlib-flash')
    end
end

return _M

