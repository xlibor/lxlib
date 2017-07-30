
local lx, _M = oo{
    _cls_    = '',
    _ext_    = 'command'
}

local app, lf, tb, str = lx.kit()
local fs, json = lx.fs, lx.json

function _M:ctor()

    self.doer = app:make('carrier.doer', self)
end

function _M:install()

    self.doer:install()
end

function _M:reset()

    self.doer:reset()
end

function _M:update()

    self.doer:update()
end

return _M

