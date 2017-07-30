
local _M = { 
    _cls_ = '',
    _ext_ = 'box'
}

local lx = require('lxlib')
local app = lx.app()

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

return _M

