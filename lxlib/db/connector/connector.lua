
local lx, _M = oo{
    _cls_    = ''
}

local app, lf, tb, str = lx.kit()
local throw = lx.throw

function _M:createConnection(config)

    local driver = self.driver
    local ldo
    local ldoType = driver .. 'Ldo'

    lx.try(function()

        ldo = app:make(ldoType, config)
    end)
    :catch(function(e)
        ldo = self:tryAgainIfCausedByLostConnection(e, ldoType, config)
    end):run()

    return ldo
end

function _M.__:tryAgainIfCausedByLostConnection(e, ldoType, config)

    if self:causedByLostConnection(e) then 
        return app:make(ldoType, config)
    end

    throw(e)
end

function _M.__:causedByLostConnection(e)

    local msg = e.msg

    return str.has(msg, {
        'server has gone away',
        'no connection to the server',
        'Lost connection',
        'is dead or not enabled',
        'Error while sending',
        'decryption failed or bad record mac',
        'server closed the connection unexpectedly',
        'SSL connection has been closed unexpectedly',
        'Error writing data to the connection',
        'Resource deadlock avoided',
    });

end

return _M

