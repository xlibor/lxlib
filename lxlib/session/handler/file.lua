
local lx, _M, mt = oo{
    _cls_     = '',
    _bond_    = 'sessionHandlerBond'
}

local app, lf, tb, str = lx.kit()

function _M:new(fs, path)

    local this = {
        fs = fs,
        path = path
    }

    return oo(this, mt)
end

function _M:open(savePath, sesssionName)

    return true
end

function _M:close()

    return true
end

function _M:read(sessionId)

    local path = self.path .. '/' .. sessionId
    local exists, err = self.fs.exists(path)
    if exists then

        return self.fs.get(path)
    end

    return ''
end

function _M:write(sessionId, data)

    local path = self.path .. '/' .. sessionId

    self.fs.put(path, data)
end

function _M:destroy(sessionId)

    local path = self.path .. '/' .. sessionId
    self.fs.delete(path)
end

function _M:gc(lifetime)

    return true
end

return _M

