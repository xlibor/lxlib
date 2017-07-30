
local _M = {
    _cls_     = '',
    _ext_    = 'box'
}

local mt = { __index = _M }

local lx = require('lxlib')
local app = lx.app()



function _M:reg()

    self.instances = {}

    if self.group then
        for _, box in ipairs(self.group) do
            tapd(self.instances, app:reg(box))
        end
    end
end

function _M:boot()

end

return _M

