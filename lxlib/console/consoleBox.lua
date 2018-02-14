
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

    app:bindFrom('lxlib.console', {
        'input', 'output'
    })

    app:single('command', 'lxlib.console.command')
    
    app:bindFrom('lxlib.console.output', {
        outputFormatter = 'formatter',
        outputFormatterStyle = 'formatterStyle'
    })

    app:single('commander',     'lxlib.console.commander')
    app:bind('lxlib.console.base.command')
    app:bind('generatorCmd',    'lxlib.console.base.generatorCmd')

    app:bindFrom('lxlib.console.schedule', {
        'event', 'callbackEvent'
    }, {prefix = 'schedule.'})
    
    app:single('schedule', 'lxlib.console.schedule.schedule')
end

function _M:boot()

    app:resolving('commander', function(cmder)
        cmder:group({ns = 'lxlib.console.base', lib = true}, function()
            cmder:add('test/run|test', 'libTestCmd@run')

            cmder:add('run', 'runCodeCmd@run')
            cmder:add('{common}/{about}|$2', 'lib#1Cmd@$2')
            cmder:add('{common}/{version}|$2', 'lib#1Cmd@$2')
            cmder:add('{common}/{help}|$2', 'lib#1Cmd@$2')

            cmder:add('app/new|new', 'appManageCmd@createApp')
            cmder:add('app/init', 'appManageCmd@initApp')
            cmder:add('app/single', 'appManageCmd@singleApp')
            cmder:add('app/{default}/get|$1App', 'appManageCmd@get#1App')
            cmder:add('app/{default}/set', 'appManageCmd@set#1App')
            cmder:add('app/appList|apps', 'appManageCmd@showApps')
            cmder:add('app/{remove}|$1', 'appManageCmd@$1App')
            
            cmder:add('env/show|env', 'envManageCmd@showAll')
            cmder:add('env/get', 'envManageCmd@get')

            cmder:add('pub/env/show|pubenv', 'pubEnvManageCmd@showAll')
            cmder:add('pub/env/get', 'pubEnvManageCmd@get')
            cmder:add('pub/env/set', 'pubEnvManageCmd@set')
            cmder:add('pub/key',     'pubEnvManageCmd@generateKey')
            
            cmder:add('box/publish|publish', 'boxPublishCmd@run')
        end)

        cmder:group({ns = 'lxlib.console.base', lib = false, app = true}, function()
            cmder:add('app/{makeLib}|$1', 'appManageCmd@$1')
            cmder:add('app/{removeLib}|$1', 'appManageCmd@$1')
            cmder:add('app/{key}|$1', 'appEnvManageCmd@generateKey')

            cmder:add('app/env/show|appenv', 'appEnvManageCmd@showAll')
            cmder:add('app/env/get', 'appEnvManageCmd@get')
            cmder:add('app/env/set', 'appEnvManageCmd@set')
            cmder:add('app/env/init', 'appEnvManageCmd@init')
            cmder:add('app/env/reset', 'appEnvManageCmd@reset')
            cmder:add('app/env/remove', 'appEnvManageCmd@remove')

        end)

        cmder:group({ns = 'lxlib.console.base', lib = false}, function()

            cmder:add('{serve}/{start}|$2', 'lib#1Cmd@$2')
            cmder:add('{serve}/{reload}|$2', 'lib#1Cmd@$2')
            cmder:add('{serve}/{stop}|$2', 'lib#1Cmd@$2')
            cmder:add('{serve}/{quit}|$2', 'lib#1Cmd@$2')

            cmder:add('make/{controller}|make/ctler', '$1MakeCmd@make')
            cmder:add('make/{model}', '$1MakeCmd@make')
            cmder:add('make/{command}', '$1MakeCmd@make')
            cmder:add('ngxconf/{update}', 'ngxConfManageCmd@$1')
            cmder:add('ngxconf/{clear}', 'ngxConfManageCmd@$1')

        end)
    end)
end

return _M

