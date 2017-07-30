
local _M = { 
    _cls_ = ''
}

local mt = { __index = _M }

local lx = require('lxlib')
local app, lf, tb, str, new = lx.kit()
local use, try, throw = lx.kit2()
local fs = lx.fs

function _M:new()

    local this = {
        loaders = {
            'lxlib.core.load.loadConfig',
            'lxlib.core.load.regBoxes',
            'lxlib.core.load.bootBoxes',
            'lxlib.core.load.regFaces'
        }
    }

    setmetatable(this, mt)

    return this
end

function _M:load()
    
    if not app.loaded then
        self:loadApp()
    end
end

function _M:handle(input, output)

    lx.try(function()
        self:load()
        self.commander = app:make('commander')
        self:loadCommands(self.commander)
        self:sendToCommander(input, output)
         
    end)
    :catch(function(e)
        echo(e.msg, e.file, e.line)
        echo(e.trace)
    end)
    :run()

end

function _M:loadCommands(cmder)

end

function _M:sendToCommander(input, output)

    local cmder = self.commander
    local cmd = cmder:match(input, output)
    if cmd then
        local isLibCmd, viaApp = cmd.isLibCmd, cmd.viaApp
        local appName = lx.env('appName')
        if (not isLibCmd) and appName == 'lxlib' then
            warn('this command should run in the application')
            return
        end
        local currApp = lx.env('currApp')
        if (not currApp) and viaApp then
            warn('this command should run in some app path')
            return
        end
        cmder:handle(cmd, input, output)
    else
        warn('not match any cmd')
    end
end

function _M:run(cmd, args)

    local input = app:make('input', args, cmd)
    local output = app:make('output')

    self:handle(input, output)
end

function _M:loadApp()

    local global = require('lxlib.base.global')

    local env = lx.env
    local appName = env('appName')

    if not appName then
        warn('not set appName')
        return
    else
        if appName == 'lxlib' then
            return
        end
    end

    local appPath = env('appPath')

    app.name = appName
    app:setBasePath(appPath)
    app.boxes = {}
    app:loadWith(self.loaders)
end

function _M:regCommand(key, command)

    app:add(key, command)
end

function _M:reportException(e)

    app:get('exception.handler'):report(e)
end

function _M:renderException(e, ctx)

    app:get('exception.handler'):render(e, ctx)
end

return _M

