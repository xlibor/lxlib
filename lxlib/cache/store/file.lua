
local lx, _M, mt = oo{
    _cls_   = '',
    _bond_  = 'cacheStoreBond'
}

local app, lf, tb, str = lx.kit()
local throw = lx.throw
local ssub = string.sub

function _M:new(files, directory)

    local this = {
        files = files,
        directory = directory
    }
    
    oo(this, mt)

    return this
end

function _M:get(key)

    local payload = self:getPayload(key)

    return payload.data, payload.forgot, payload.time
end

function _M.__:getPayload(key)

    local path = self:path(key)

    if not self.files.exists(path) then
        return {}
    end

    local expire, contents

    local ok = lx.try(function()
        contents = self.files.get(path, true)
    end):catch(function(e)
        return {}
    end):run()

    if not ok or not contents then

        return {}
    end

    expire = ssub(contents, 1, 10)
    expire = tonumber(expire) or 0
    local time = lf.time()
    if time >= expire then
        self:forget(key)

        return {forgot = true}
    end

    local data = ssub(contents, 11)
    data = lf.base64De(data)

    time = expire - time

    return {data = data, time = time}
end

function _M:put(key, value, seconds)

    value = self:expiration(seconds) .. lf.base64En(value)

    local path = self:path(key)

    self:createCacheDirectory(path)

    self.files.put(path, value)

    return true
end

function _M:update(key, value)

    local data, forgot, expire = self:get(key)
    if not data then return end

    self:put(key, value, expire)

    return true
end

function _M.__:createCacheDirectory(path)

    local files = self.files
    local dirName = files.dirname(path)

    if not files.exists(dirName) then 
        files.makeDir(dirName, 0777, true, true)
    end
end

function _M:forever(key, value)

    self:put(key, value, 0)
end

function _M:forget(key)

    local file = self:path(key)

    if self.files.exists(file) then

        self.files.delete(file)
        return true
    end

    return false
end

function _M:flush()

    if self.files.isDir(self.directory) then
        for _, file in ipairs(self.files.files(self.directory)) do
            self.files.delete(file)
        end
    end
end

function _M.__:path(key)

    local hash = lf.md5(key)
 
    return self.directory .. '/' .. hash
end

function _M.__:expiration(seconds)

    local time = lf.time() + seconds

    if seconds == 0 or time > 9999999999 then
        return 9999999999
    end

    return time
end

function _M:getFilesystem()

    return self.files
end

function _M:getDirectory()

    return self.directory
end


return _M

