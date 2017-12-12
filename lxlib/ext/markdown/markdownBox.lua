
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'box'
}

local app, lf, tb, str, new = lx.kit()
local fs = lx.fs

function _M:boot()

end

function _M:dependOn()

    return {
        discount = ""
    }
end

function _M:reg()

    app:single('markdown', 'lxlib.ext.markdown.markdown')
end

return _M

