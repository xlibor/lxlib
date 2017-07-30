
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()
local fs = lx.fs

function _M:new()

    local this = {
    }
    
    return oo(this, mt)
end

function _M:create(name, path, subPath)

    path = self:getPath(name, path)
 
    return path
end

function _M.__:getPath(name, path)

    local appName = lx.env('appName')
    name = appName .. '.db.shift.' .. name

    local rootPath = path or lx.env('rootPath')
    name = str.replace(name, '%.', '/')
    local path, name = fs.split(name)
    name = self:getDatePrefix()..'_'..name
    path = rootPath..'/'..path..'/'..name..'.lua'

    return path
end
 
function _M.__:getDatePrefix()

    return lf.datetime('%Y_%m_%d_%H%M%S')
end

return _M

