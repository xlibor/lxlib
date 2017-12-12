
local lx, _M = oo{
    _cls_ = '',
    _ext_ = 'box'
}

local app, lf, tb, str = lx.kit()

function _M:reg()

    app:single('image', 'lxlib.ext.image.imageManager')
end

function _M:dependOn()

    return {
        magick = ''
    }
end

function _M:boot()

end

return _M

