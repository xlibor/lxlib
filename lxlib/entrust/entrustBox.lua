
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'box'
}

local app, lf, tb, str = lx.kit()
local fs = lx.fs

function _M:boot()

    local currPath = lx.getPath(true)
    local confPath = fs.exists(currPath .. '/../conf')
    self:publish(
        {
            [confPath .. '/*'] = lx.dir('conf')
        }, 'config'
    )

    self:command('entrust.cmd', {
        ['entrust.shift'] = 'entrust@run'
    })

    self:bladeCustom()
end

function _M:reg()

    self:regEntrust()
end

function _M.__:bladeCustom()

    local custom = app:get('view.blade.custom')

    custom:add('can', function(text)
        return fmt('if App.gate:check(%s) then ', text)
    end)
    custom:add('role', function(text)
        
        return fmt('if Entrust.hasRole(%s) then ', text)
    end)
    custom:add('endrole', function()
        
        return 'end'
    end)
    custom:add('permission', function(text)
        
        return fmt('if Entrust.can(%s) then ', text)
    end)
    custom:add('endpermission', function()
        
        return 'end'
    end)
    custom:add('ability', function(text)
        
        return fmt('if Entrust.ability(%s) then ', text)
    end)
    custom:add('endability', function()
        
        return 'end'
    end)
end

function _M.__:regEntrust()

    app:bindFrom('lxlib.entrust.mix', {
        'entrustUserMix', 'entrustRoleMix', 'entrustPermissionMix'
    })
    app:bindFrom('lxlib.entrust', {
        'entrust', 'entrustPermission', 'entrustRole'
    })
    app:bondFrom('lxlib.entrust.bond', {
        'entrustRoleBond', 'entrustUserBond', 'entrustPermissionBond'
    })
end

return _M

