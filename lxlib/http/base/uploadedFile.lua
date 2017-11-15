
local lx, _M = oo{
    _cls_ = '',
    _ext_ = 'fileInfo'
}

local fs = lx.fs

function _M:ctor(path, originalName, mimeType)

    self.originalName = originalName
    mimeType = mimeType or 'application/octet-stream'
    self.mimeType = self:guessMimetype(mimeType)
end

-- function _M:move(directory, name)

-- end

function _M:isValid()

    return true
end

function _M:getClientOriginalName()

    return self.originalName
end

function _M:getClientOriginalExtension()

    return self.extension
end

function _M.__:guessMimetype(clientMimeType)

    return clientMimeType
end

function _M.__:guessExtension()

    return self.extension
end

return _M

