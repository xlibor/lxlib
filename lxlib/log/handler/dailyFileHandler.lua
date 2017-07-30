
local lx, _M = oo{
    _cls_ = '',
    _ext_ = 'logFileHandler'
}

local app, lf, tb, str = lx.kit()
local Logger = lx.use('logger')
local Dt = lx.use('datetime')
local fs = lx.fs

--@param string         fileName
--@param num|null       level
--@param bool|null      bubble
--@param num|null       maxFiles

function _M:ctor(fileName, level, bubble, maxFiles)

    useLocking = useLocking or false
    bubble = lf.needTrue(bubble)
    level = level or Logger.static.debug
    maxFiles = maxFiles or 0
    self.fileName = fileName
    self.maxFiles = maxFiles
    self.nextRotation = Dt.tomorrow()
    self.fileNameFormat = '{fileName}-{date}'
    self.dateFormat = 'Y-m-d'
    self.__skip = true
    self:__super(_M, 'ctor', self:getTimedFilename(), level, bubble)
end

-- {@inheritdoc}

function _M:close()

    self:__super(_M, 'close')
    if self.mustRotate then
        self:rotate()
    end
end

function _M:setFilenameFormat(fileNameFormat, dateFormat)

    self.fileNameFormat = fileNameFormat
    self.dateFormat = dateFormat
    self.file = self:getTimedFilename()
    self:close()
end

-- {@inheritdoc}

function _M.__:write(record)

    -- on the first record written, if the log is new, we should rotate (once per day)
    if not self.mustRotate then
        self.mustRotate = not fs.exists(self.file)
    end
    if self.nextRotation:lt(record.datetime) then
        self.mustRotate = true
        self:close()
    end

    self:__super(_M, 'write', record)
end

-- Rotates the files.

function _M.__:rotate()

    -- update fileName
    self.file = self:getTimedFilename()
    self.nextRotation = Dt.tomorrow()
    -- skip GC of old logs if files are unlimited
    if 0 == self.maxFiles then
        
        return
    end

    -- local logFiles = glob(self:getGlobPattern())
    -- if self.maxFiles >= #logFiles then
    --     -- no files to remove
        
    --     return
    -- end
    -- -- Sorting the files by name to remove the older ones
    -- usort(logFiles, function(a, b)
        
    --     return strcmp(b, a)
    -- end)
    -- for _, file in pairs(tb.slice(logFiles, self.maxFiles)) do
    --     if is_writable(file) then
    --         -- suppress errors here as unlink() might fail if two processes
    --         -- are cleaning up/rotating at the same time
    --         set_error_handler(function(errno, errstr, errfile, errline)
    --         end)
    --         unlink(file)
    --         restore_error_handler()
    --     end
    -- end

    self.mustRotate = false
end

function _M.__:getTimedFilename()

    local dirName, fileName, extName = fs.pathinfo(self.fileName)

    local timedFilename = str.replace(dirName .. '/' .. self.fileNameFormat,
        {'{fileName}', '{date}'}, {fileName, Dt.now():fmt(self.dateFormat)})
    if str.len(extName) > 0 then
        timedFilename = timedFilename .. '.' .. extName
    end
    
    return timedFilename
end

function _M.__:getGlobPattern()

    local fileInfo = pathinfo(self.fileName)
    local glob = str.replace(fileInfo['dirname'] .. '/' .. self.fileNameFormat, {'{fileName}', '{date}'}, {fileInfo['fileName'], '*'})
    if not lf.isEmpty(fileInfo['extension']) then
        glob = glob .. '.' .. fileInfo['extension']
    end
    
    return glob
end

return _M

