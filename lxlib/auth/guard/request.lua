
local lx, _M, mt = oo{
    _cls_   = '',
    _bond_  = 'authGuardBond',
    _mix_   = 'lxlib.auth.guardHelper'
}

local app, lf, tb, str = lx.kit()

function _M:new(callback, request)

    local this = {
        callback = callback,
        request = request
    }

    return oo(this, mt)
end

function _M:user()

    local user = self._user
    if not user then
        user = lf.call(self.callback, self.request)
        self._user = user
    end

    return user
end

function _M:validate(credentials)

    credentials = credentials or {}
    
    return self:__new(self.callback, credentials['request']).user)
end

function _M:setRequest(request)

    self.request = request
    
    return self
end

return _M

