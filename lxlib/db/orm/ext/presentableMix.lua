
local _M = {
    _cls_    = '',
}

local lx = require('lxlib')
local app, lf, tb, str, new = lx.kit()

function _M:ctor()

    self.presenterInstance = false
    self.presentableInstance = false
end

function _M:present(key)

    if not rawget(self, 'presenter') then
        error('Please set the presenter property to your presenter path.')
    end

    if not self.presenterInstance then
        self.presenterInstance = new(self.presenter, self)
    end

    if not key then
        return self.presenterInstance
    else
        return self.presenterInstance:get(key)
    end
end

return _M

