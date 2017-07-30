
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'command'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        signature = 'auth:clear-resets {name? : The name of the password broker}',
        description = 'Flush expired password reset tokens'
    }

    return oo(this, mt)
end

function _M:fire()

    app['auth.password']:broker(self:arg('name')):getRepository():deleteExpired()
    self:info('Expired reset tokens cleared!')
end

return _M

