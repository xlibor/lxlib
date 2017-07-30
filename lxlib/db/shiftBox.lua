
local _M = { 
    _cls_ = '',
    _ext_ = 'box'
}

local mt = { __index = _M }

local lx = require('lxlib')
local app = lx.app()

function _M:reg()

    app:bond('shiftDoerBond',     'lxlib.db.shift.doerBond')
    app:bind('shift',             'lxlib.db.shift.shift')
    app:single('shifter',         'lxlib.db.shift.shifter')
    app:single('shift.dbDoer',    'lxlib.db.shift.dbDoer')
end

function _M:boot()

    app:resolving('commander' ,function(cmder)

        app:bind('shift.creator', 'lxlib.db.shift.creator')

        cmder:group({ns = 'lxlib.db.cmd.shift', lib = false, app = true}, function()
            cmder:add('{shift}/{run}|shift', '$1ManageCmd@$2')
            cmder:add('{shift}/{rollback}', '$1ManageCmd@$2')
            cmder:add('{shift}/{reset}', '$1ManageCmd@$2')
            cmder:add('{shift}/{refresh}', '$1ManageCmd@$2')
            cmder:add('{shift}/{install}', '$1ManageCmd@$2')

            cmder:add('make/{shift}', '$1MakeCmd@make')
            cmder:add('session/table', 'sessionTableCmd@make')
        end)
    end)

end
 
return _M

