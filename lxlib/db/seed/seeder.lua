
local lx, _M, mt = oo{ 
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()
local fs = lx.fs

function _M:new(command)

    local this = {
        command = command
    }

    return oo(this, mt)
end

function _M:call(class)

    self:resolve(class):run()

    local cmd = self.command or app:get('app.command')
    if cmd then
        cmd:info('seeded: ' .. class)
    end
end

function _M:resolve(class)

    local instance
    local cmd = self.command
    if cmd then
        instance = cmd:getSeeder(class)
    else
        app:bind(class)
        instance = app:make(class)
    end

    return instance
end

return _M

