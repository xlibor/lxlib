
local lx, _M = oo{
    _cls_ = '',
    _ext_ = 'box'
}

local app, lf, tb, str = lx.kit()

function _M:reg()

    app:bindFrom('lxlib.log.handler', {
        logBaseHandler          = 'baseHandler',
        logNullHandler          = 'nullHandler',
        logFileHandler          = 'fileHandler',
        logDailyFileHandler     = 'dailyFileHandler',
        
    })

    app:bindFrom('lxlib.log.formatter', {
        logLineFormatter        = 'lineFormatter',
        logNormalizerFormatter  = 'normalizerFormatter'
    })

    app:bondFrom('lxlib.log.bond', {
        logFormatterBond        = 'formatterBond',
        logHandlerBond          = 'handlerBond',
        loggerBond              = 'loggerBond'
    })

    app:single('logger',            'lxlib.log.logger')
    app:single('logging',       'lxlib.log.logManager')
end

function _M:boot()

    app('logging'):resolve()
end

return _M

