
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'command'
}

local app, lf, tb, str = lx.kit()
local fs = lx.fs

function _M:ctor()

    self.views = {
        'auth/login.html', 'auth/register.html',
        'auth/password/email.html', 'auth/password/reset.html', 
        'layout/app.html', 'home.html' 
    }
    self.ctlers = {
        'forgotPwd.lua', 'login.lua', 'reg.lua', 'resetPwd.lua'
    }
end

function _M:run()

    self:createDirs()
    self:exportViews()
    self:makeForRoute()
    self:info('Authentication scaffolding generated successfully.')
end

function _M.__:createDirs()

    local layout = lx.dir('res', 'view/layout')
    if not fs.isDir(layout) then
        fs.makeDir(layout)
    end
    local password = lx.dir('res', 'view/auth/password')
    if not fs.isDir(layout) then
        fs.makeDir(layout)
    end

end

function _M.__:exportViews()

    local currDir = lx.getPath(true)

    for _, value in pairs(self.views) do
        fs.copy(
            currDir .. '/stub/view/' .. value,
            lx.dir('res', 'view/' .. value)
        )
    end
end

function _M.__:makeForRoute()

    local currDir = lx.getPath(true)

    for _, value in pairs(self.ctlers) do
        fs.copy(
            currDir .. '/stub/ctler/' .. value,
            lx.dir('app', 'http/ctler/auth/' .. value)
        )
    end

    fs.copy(
        currDir .. '/stub/ctler/home.lua',
        lx.dir('app', 'http/ctler/home.lua')
    )

    fs.copy(
        currDir .. '/stub/map/auth.lua',
        lx.dir('map', 'load/auth.lua')
    )

end

return _M

