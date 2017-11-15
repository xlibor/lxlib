
local lx, _M = oo{ 
    _cls_ = '',
    _ext_ = 'manager'
}

local app, lf, tb, str = lx.kit()

function _M:ctor()

end

function _M:load(imageName)

    return self:resolve():load(imageName)
end

function _M:driver(driver)

    return self:resolve(driver)
end

function _M:createGdDriver(config)

    local gd = app:make('lxlib.ext.image.gd.driver', config)

    return gd
end

function _M:createImagickDriver(config)

    local imagick = app:make('lxlib.ext.image.imagick.driver', config)

    return imagick
end

function _M.__:getConfig(name)

    return app:conf('image.drivers.' .. name)
end

function _M:getDefaultDriver()

    return app:conf('image.driver')
end

function _M:_run_(method)

    return 'driver'
end

return _M

