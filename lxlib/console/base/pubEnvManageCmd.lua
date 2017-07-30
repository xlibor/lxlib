
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
local fs = lx.fs

function _M:ctor()
    
end

function _M:showAll()

    local showRaw = self:arg('raw')

    if not showRaw then
        local col = self:getEnvCol()
        self:text(col:toJson())
    else
        local raw = self:getEnvRaw()
        self:text(raw)
    end
end

function _M:get()

    local key = self:arg('key')
    if key then
        local col = self:getEnvCol()

        self:text(col:get(key))
    else
        self:warn('not input key')
    end
end

function _M:set()

    local key, value = self:arg('key'), self:arg('value')

    if key then
        local col = self:getEnvCol()
        if lf.isTrueStr(value) then
            value = true
        else
            value = false
        end
        col:set(key, value)

        local jsonStr = col:toJson(_, true)
        self:text(jsonStr)
        fs.put(self.envPath, jsonStr)
    else
        self:warn('not input key')
    end
end

return _M

