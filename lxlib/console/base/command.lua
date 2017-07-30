
local lx, _M = oo{ 
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()
local fs = lx.fs

function _M:ctor()
    
    local env = lx.env
    self.envPath = lx.g('envPath')
    self.appEnvPath = env('appEnvPath')
    local appName = env('appName')
    self.appName = appName
    self.appPath = env('appPath')
    local rootPath = env('rootPath')
    self.rootPath = rootPath
    self.libPath = rootPath .. '/lxlib'
    self.pubPath = rootPath .. '/lxpub'

    if appName then
        self.lib4appPath = self.appPath .. '/vendor/lxlib'
    end

    self.currApp = env('currApp')
end

function _M:getEnvRaw()

    local envPath = self.envPath
    local envStr = fs.get(envPath)

    return envStr
end

function _M:getEnvAll()

    local envStr = self:getEnvRaw()

    local env = lx.json.decode(envStr)

    return env
end

function _M:getEnvCol()

    local env = self:getEnvAll()
    local col = lx.col(env)
    col:itemable():dotable()

    return col
end

function _M:envGet(key)

    if key then
        local col = self:getEnvCol()

        return col:get(key)
    else
        self:warn('not input key')
    end
end

function _M:envSet(key, value)

    if key then
        local col = self:getEnvCol()
        col:set(key, value)

        local jsonStr = col:toJson(_, true)
        fs.put(self.envPath, jsonStr)
    else
        self:warn('not input key')
    end
end

return _M

