
local lx, _M, mt = oo{
    _cls_ = ''
}

local fs = lx.fs

function _M:new(path)
     
    local this = {
        fpath = path
     }

     return oo(this, mt)
end

function _M.d__:baseName()

    return fs.basename(self.fpath)
end

function _M.d__:fileName()

    return fs.fileName(self.fpath)
end

function _M.d__:path()

    return fs.dirName(self.fpath)
end

function _M.d__:pathName()

    return fs.fullPath(self.fpath)
end

function _M.d__:fullPath()

    return fs.fullPath(self.fpath)
end

function _M.d__:extension()

    return fs.extension(self.fpath)
end

_M.d__.ext = _M.d__.extension

function _M.d__:atime()

    return fs.atime(self.fpath)
end

function _M.d__:ctime()

    return fs.ctime(self.fpath)
end

function _M.d__:mtime()

    return fs.mtime(self.fpath)
end

function _M.d__:size()

    return fs.size(self.fpath)
end

function _M.c__:isFile()

    return fs.isFile(self.fpath)
end

function _M.c__:isDir()

    return fs.isDir(self.fpath)
end

function _M.c__:isLink()
    
    return fs.isLink(self.fpath)
end
 
return _M

