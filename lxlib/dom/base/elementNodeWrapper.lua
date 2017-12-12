
local wrap = function(_M)

local lx = require('lxlib')
local app, lf, tb, str, new = lx.kit()

function _M:getAttr(attrName)

    local attrs = self.attributes
    if attrs then
        return attrs[attrName]
    end
end

end

return wrap

