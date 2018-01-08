
local lx, _M = oo{ 
    _cls_ = '',
    _ext_ = 'box'
}

local app, lf, tb, str = lx.kit()
local fs = lx.fs

function _M:reg()

end

function _M:boot()

    if app:runningInConsole() then
        return
    end
    self:setRootNamespace()

    self:loadRoutes()
end

function _M:setRootNamespace()

    local namespace = app:conf('app.namespace')
    if not namespace then
        return
    end

    if not app:runningInConsole() then
        app.url:setRootControllerNamespace(namespace)
    end
end

function _M:loadRoutes()
    
    if self:__has('map') then
        self:map()
    end
end

function _M:autoload()

    local router = app.router

    local loadDir = lx.dir('map', 'load')
    if fs.exists(loadDir) then
        local routes = fs.files(lx.dir('map', 'load'), 'n', function(file)
            local name, ext = file:sub(1, -5), file:sub(-3)

            if ext == 'lua' then
                return name
            end
        end)
        if #routes > 0 then
            for _, route in ipairs(routes) do
                require('.map.load.' .. route)(router)
            end
        end
    end
end

return _M

