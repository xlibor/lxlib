
local lx, _M = oo{
    _cls_ = '',
    _ext_ = 'command',
    sign = {
        showAll = {
            raw = {short = 'r', opt = true, value = true}
        },
        get = {
            key = {index = 1}
        },
        set = {
            key = {short = 'k', index = 1},
            value = {short = 'v', index = 2}
        }
    }
}

local app, lf, tb, str = lx.kit()
local fs, json = lx.fs, lx.json
 
function _M:ctor()
 
end

function _M:init()

    local appEnvPath = self.appEnvPath
    if not appEnvPath then
        local appPath = self.appPath
        local ret = self:confirm(
            'Do you want to create env.json in app('..appPath..')?',
            false
        )
        
        if ret then
            appEnvPath = appPath..'/env.json'
            fs.put(appEnvPath, [[{}]])
            self:info(appEnvPath..' created successfully.')
        end
    else
        self:warn('app env inited.')
    end
end

function _M:isValid()

    local envPath = self.appEnvPath
    if (not envPath) and (self.input.subCmd ~= 'init') then
        self:warn('not set app env file')
    end

    return envPath and true or false
end

function _M:getEnvCol()

    local envStr = self:getEnvRaw()
    local col = json.decode(envStr)
    col = lx.col(col)
    col:itemable():dotable()

    return col
end

function _M:getEnvRaw()

    local envPath = self.appEnvPath
    local envStr = fs.get(envPath)

    return envStr
end

function _M:showAll()

    if not self:isValid() then return end

    local showRaw = self:arg('raw')

    if not showRaw then
        local col = self:getEnvCol()
        self:info(col:toJson())
    else
        local raw = self:getEnvRaw()
        self:info(raw)
    end
end

function _M:get()

    if not self:isValid() then return end

    local key = self:arg('key')
    if key then
        local col = self:getEnvCol()

        self:info(col:get(key))
    end
end

function _M:set()

    if not self:isValid() then return end

    local key, value = self:arg('key'), self:arg('value')

    if key then
        local col = self:getEnvCol()
        if lf.isBoolStr(value) or lf.isNilStr(value) then
            value = lf.strToBool(value)
        end
        if lf.isStr(value) then
            if value == '{}' then
                value = lx.n.obj{}
            end
        end
        
        col:set(key, value)

        local jsonStr = col:toJson(_, true)
        self:info(jsonStr)
        fs.put(self.appEnvPath, jsonStr)
    end
end

function _M:reset()

    local appEnvPath = self.appEnvPath
    if appEnvPath then
        local appPath = self.appPath
        local ret = self:confirm(
            'Do you want to reset env.json in app('..appPath..')?',
            false
        )
        
        if ret then
            appEnvPath = appPath..'/env.json'
            fs.put(appEnvPath, '{}')
            self:info(appEnvPath..' reseted successfully.')
        end
    else
        self:warn('app env not inited.')
    end

end

function _M:remove()

    local appEnvPath = self.appEnvPath
    if appEnvPath then
        local appPath = self.appPath
        local ret = self:confirm(
            'Do you want to remove env.json in app('..appPath..')?',
            false
        )
        
        if ret then
            appEnvPath = appPath..'/env.json'
            fs.remove(appEnvPath)
            self:info(appEnvPath..' removed successfully.')
        end
    else
        self:warn('app env not inited.')
    end

end

return _M

