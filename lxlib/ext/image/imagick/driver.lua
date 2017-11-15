
local lx, _M, mt = oo{
    _cls_   = '',
}

local app, lf, tb, str, new = lx.kit()
local fs = lx.fs

local Magick = require('magick.init')

function _M:ctor()

end

function _M:load(imageName)

    local img = assert(Magick.load_image(imageName))

    return img
end

return _M

