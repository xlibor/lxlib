
local lx, _M = oo{
    _cls_ = '',
    _ext_ = 'box'
}

local app, lf, tb, str, new = lx.kit()

function _M:reg()

    app:bindFrom('lxlib.dt', {
        'datetime', 'timezone', 'dateInterval',
        'datePeriod'
    })

end

function _M:boot()

    local timezone = app:conf('app.timezone')

    if timezone then
        app:single('app.timezone', 'lxlib.dt.timezone', function()

            return new('timezone', timezone)
        end)
    end
end

return _M

