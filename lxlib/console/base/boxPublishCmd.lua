
local lx, _M = oo{ 
    _cls_ = '',
    _ext_ = 'command'
}

local mt = { __index = _M }

local app, lf, tb, str = lx.kit()
local fs = lx.fs

local Box = lx.use('box')

function _M:ctor()

end

function _M:run()

    local tags = {}
    local tag = self:arg('tag')
    if tag then
        if str.find(tag, ',') then
            tags = str.split(tag, ',')
        else
            tags = {tag}
        end
    end

    if #tags > 0 then
        for _, tag in ipairs(tags) do
            self:publishTag(tag)
        end
    else
        self:publishTag()
    end
end

function _M:publishTag(tag)

    local box = self:arg('box')
    local paths = Box.pathsToPublish(box, tag)

    if lf.isEmpty(paths) then
        tag = tag or 'unknown'
        return self:comment('nothing to publish for tag ' .. tag)
    end

    for pathFrom, pathTo in pairs(paths) do
        if fs.isFile(pathFrom) then
            self:publishFile(pathFrom, pathTo)
        elseif fs.isDir(pathFrom) then
            self:publishDirectory(pathFrom, pathTo)
        elseif str.find(pathFrom, '%*') then
            self:publishDirectory(pathFrom, pathTo)
        else
            self:error('can not locate path:' .. pathFrom)
        end
    end

    self:info(str.fmt('publishing complete for tag [%s]!', tag))
end

function _M.__:publishFile(pathFrom, pathTo)

    if fs.exists(pathTo) and not self:arg('force') then
        return
    end

    self:createParentDirectory(fs.dirname(pathTo))

    fs.copy(pathFrom, pathTo, true)

    self:status(pathFrom, pathTo, 'File')
end

function _M.__:publishDirectory(pathFrom, pathTo)

    fs.copy(pathFrom, pathTo, 'rf')

    self:status(pathFrom, pathTo, 'Directory')
end

function _M.__:createParentDirectory(directory)

    if not fs.isDir(directory) then
        fs.makeDir(directory, 0755, true)
    end
end

function _M.__:status(pathFrom, pathTo, pathType)

    self:line(str.fmt('<info>copied %s</info> <comment> [%s]</comment> <info> To </info> <comment>[%s]</comment>', pathType, pathFrom, pathTo))
end

return _M

