
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'box'
}

local app, lf, tb, str, new = lx.kit()
local fs = lx.fs

function _M:boot()

    local currPath = lx.getPath(true)
    local confPath = fs.exists(currPath .. '/conf')

    self:publish({
            [currPath .. '/conf/*'] = lx.dir('conf')
        }, 'tagging')

    self:publish({
            [currPath .. '/shift/*'] = lx.dir('db', '/shift')
        }, 'tagging')

end

function _M:reg()

    app:bindFrom('lxlib.ext.tagging.model', {
        'tag', 'tagged'
    }, {prefix = 'tagging.'})

    app:bind('tagging.taggable', 'lxlib.ext.tagging.taggable')
    app:single('tagging.util', 'lxlib.ext.tagging.util')
end

return _M

