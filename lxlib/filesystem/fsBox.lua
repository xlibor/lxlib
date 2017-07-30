
local lx, _M = oo{
    _cls_ = '',
    _ext_ = 'box'
}

local app = lx.app()

function _M:reg()
 
    app:bind('files',       'lxlib.filesystem.fs', '')
    app:bind('fileInfo',    'lxlib.filesystem.fileInfo')
end

function _M:boot()

end

return _M

