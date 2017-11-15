
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str, new = lx.kit()
local fs = lx.fs

function _M:new()

    local this = {
        mime = nil,
        dirname = nil,
        basename = nil,
        extension = nil,
        filename = nil
    }
    
    return oo(this, mt)
end

function _M:setFileInfoFromPath(path)

    local dirname, basename, extension = fs.pathinfo(path)
    self.dirname = dirname
    self.basename = basename
    self.extension = extension
    self.filename = filename
    if fs.exists(path) and fs.isFile(path) then
        self.mime = fs.mimeType(path)
    end
    
    return self
end

-- Get file size
-- @return mixed

function _M:filesize()

    local path = self:basePath()
    if fs.exists(path) and fs.isFile(path) then
        
        return fs.size(path)
    end
    
    return false
end

-- Get fully qualified path
-- @return string

function _M:basePath()

    if self.dirname and self.basename then
        
        return self.dirname .. '/' .. self.basename
    end
    
    return nil
end

return _M

