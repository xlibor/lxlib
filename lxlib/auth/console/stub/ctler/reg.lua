
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'controller',
    _mix_ = 'lxlib.auth.regUser'
}

local User = lx.use('.app.model.user')

function _M:ctor()

    self.redirectTo = '/home'
    self:setBar('guest')
end

function _M:create(data)

    local user = User:create{
        name        = data.name,
        email        = data.email,
        password    = Hash.make(data.password)
    }

    return user
end

function _M.__:validator(data)

    return Validator.make(data,
        {
            name = 'required|max:255',
            email = 'required|email|max:255|unique:users',
            password = 'required|min:6|confirmed'
        }
    )
end

return _M

