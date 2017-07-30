
local lx, _M = oo{
    _cls_ = '',
    _ext_ = 'box'
}

local app = lx.app()

function _M:reg()
 
    self:regBond()

    -- base
    app:bind('exception', 'lxlib.exception.exception')
    app:bind('exception.raiser', 'lxlib.exception.raiser')
    app:bind('exception.trigger', 'lxlib.exception.trigger')
    app:bind('exception.handler', 'lxlib.exception.handler')

    local basePath = 'lxlib.exception.base'
    
    -- common
    app:bindFrom(basePath, {
        'runtimeException',
        'logicException',
        'errorException',
        'fatalErrorException'
    })

     -- runtimeException
    app:bindFrom(basePath, {
         'outOfBoundsException',
         'overflowException',
         'rangeException',
         'underflowException',
         'unexpectedValueException',
         'moduleNotFoundException'
    })

     -- logicException
    app:bindFrom(basePath, {
         'badFunctionCallException',
         'badMethodCallException',
         'domainException',
         'invalidArgumentException',
         'lengthException',
         'outOfRangeException'
    })
 
end

function _M:regBond()
 
    app:bond('exceptionHandlerBond', 'lxlib.exception.bond.handlerBond')
end

function _M:boot()

end
 
return _M

