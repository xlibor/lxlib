
local lx, _M = {
    _cls_ = '',
    _ext_ = 'fileInfo'
}

local fs = lx.fs

function _M:ctor(path, originalName, mimeType)

    self.originalName = originalName
    self.oriName = originalName
    self.mimeType = self:guessMimetype(mimeType)
end

function _M:move()

end

function _M.__:guessMimetype(clientMimeType)

    return clientMimeType
end

return _M

