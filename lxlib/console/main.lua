
local _M = {
    _cls_    = ''
}

local lx = require('lxlib')
local fs = lx.fs

function _M.handle(args)
 
    local env = lx.env
    local appPath = env('appPath')
    local appName = env('appName')
    local appMain

    if appPath then
        local appMainFile = appPath..'/main.lua'
        if fs.exists(appMainFile) then
            appMain = require(appName..'.main')
        end
    end

    if appMain then

        appMain(args)
    else
        local app = lx.n.app()
        app:single('console.kernel',    'lxlib.console.kernel')
        local input = app:make('input', args)
        local output = app:make('output')
        local kernel = app:make('console.kernel')

        kernel:handle(input, output)
    end
end

return _M

