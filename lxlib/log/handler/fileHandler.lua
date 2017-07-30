
local lx, _M = oo{
    _cls_ = '',
    _ext_ = 'logBaseHandler'
}

local app, lf, tb, str = lx.kit()
local Logger = lx.use('logger')
local fs = lx.fs

-- @param string            file
-- @param int|null          level   The minimum logging level at which this handler will be triggered
-- @param bool|null         bubble  Whether the messages that are handled can bubble up the stack or not

function _M:ctor(file, level, bubble)

    self.__skip = true
    self:__super(_M, 'ctor', level, bubble)
    
    bubble = lf.needTrue(bubble)
    level = level or Logger.static.debug

    self.file = file

end

-- {@inheritdoc}

function _M:close()

end

-- {@inheritdoc}

function _M.__:write(record)

    local file = self.file

    fs.writeCache(file, record.formatted)
end

function _M.__:createDir()

    self.dirCreated = true
end

return _M

