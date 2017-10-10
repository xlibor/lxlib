
local lx, _M = oo{ 
    _cls_ = '',
    _ext_ = 'box'
}

local app = lx.app()

function _M:reg()

    app:bind('seeder',             'lxlib.db.seed.seeder')

end

function _M:boot()

    app:resolving('commander', function(cmder)

        cmder:group({ns = 'lxlib.db.cmd.seed', lib = false, app = true}, function()
            cmder:add('db/seed|seed', 'seedManageCmd@run')
            cmder:add('make/{seeder}', '$1MakeCmd@make')
        end)
    end)
end

return _M

