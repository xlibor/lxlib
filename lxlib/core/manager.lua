
local lx, _M, mt = oo{
    _cls_ = '',
}

local app, lf, tb, str = lx.kit()
local throw = lx.throw

function _M:new()

    local this = {
        customCreators = {},
        drivers = {},
        resolves = {},
        inCtx = false
    }
    
    return oo(this, mt)
end

function _M:resolve(name)

    if not name then
        name = self:getDefaultDriver()
    end

    if not name then
        throw('invalidArgumentException', 'driver not configed.')
    end

    local drivers = self:getDrivers()
    local driver = drivers[name]

    if driver then
        return driver
    end

    local config = self:getConfig(name)

    if not config then
        throw('invalidArgumentException', 
            fmt('driver [%s] is not defined.', name)
        )
    end

    local driverName = config.driver
 
    driver = self:createDriver(config)
    drivers[name] = driver

    return driver
end

_M.driver = _M.resolve

function _M.__:createDriver(config)

    local driverName = config.driver
    driverName = str.studly(driverName)

    local method = 'create' .. driverName .. 'Driver'

    if self.customCreators[method] then
        return self:callCustomCreator(config)
    elseif self[method] then
        return self[method](self, config)
    else
        error('driver ' .. driverName .. ' not supported.')
    end
end

function _M:getConfig(driver) end

function _M:callCustomCreator(config)

    local driver = config.driver
    return self.customCreators[driver](config)
end

function _M:extend(driver, callback)

    self.customCreators[driver] = callback

    return self
end

function _M:getDrivers()

    local drivers, ctx, key
    local inCtx = self.inCtx

    if inCtx then
        ctx = app:ctx()
        key = self.__cls .. 'Drivers'

        drivers = ctx.drivers[key]
        if not drivers then
            drivers = {}
            ctx.drivers[key] = drivers
        end
    else
        drivers = self.drivers
    end

    return drivers
end
 
return _M

