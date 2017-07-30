
local _M = { 
    _cls_ = ''
}

local mt = { __index = _M }

local lx = require('lxlib').load(_M)
local app, lf, tb, str = lx.kit()

local redisBase = require('lxlib.resty.redis')

function _M:new(option)

    local this = {
        timeout = option.timeout or 1000,
        host = option.host,
        port = option.port or 6379,
        maxIdle = option.maxIdle or 60000,
        poolSize = option.poolSize or 100,
        password = option.password
    }

    setmetatable(this, mt)

    return this
end

function _M:ctor(option)

end

function _M:connect(redis)  

    redis:set_timeout(self.timeout)

    local ok, err =  redis:connect(self.host, self.port)
    if ok then
        local count = redis:get_reused_times()
        local password = self.password
        if count == 0 and self.password then
            redis:auth(password)
        end
    end

    return ok, err
end

function _M:setKeepalive(redis)

    return redis:set_keepalive(self.maxIdle, self.poolSize) 
end

function _M:initPipeline()

    self._reqs = {}
end

local function isRedisNull(res)

    if type(res) == "table" then
        for k,v in pairs(res) do
            if v ~= ngx.null then
                return false
            end
        end
        return true
    elseif res == ngx.null then
        return true
    elseif res == nil then
        return true
    end

    return false
end

function _M:commitPipeline()

    local reqs = self._reqs

    if nil == reqs or 0 == #reqs then
        return {}, "no pipeline"
    else
        self._reqs = nil
    end

    local redis, err = redisBase:new()
    if not redis then
        return nil, err
    end

    local ok, err = self:connect(redis)
    if not ok then
        return {}, err
    end

    redis:initPipeline()

    for _, vals in ipairs(reqs) do
        local fun = redis[vals[1]]
        table.remove(vals, 1)

        fun(redis, unpack(vals))
    end

    local results, err = redis:commitPipeline()
    if not results or err then
        return {}, err
    end

    if isRedisNull(results) then
        results = {}
    end
    
    self:setKeepalive(redis)

    for i,value in ipairs(results) do
        if isRedisNull(value) then
            results[i] = nil
        end
    end

    return results, err
end

function _M:pipeline(callback)
    
end

function _M:subscribe(channel)

    local redis, err = redisBase:new()
    if not redis then
        return nil, err
    end

    local ok, err = self:connect(redis)
    if not ok or err then
        return nil, err
    end

    local res, err = redis:subscribe(channel)
    if not res then
        return nil, err
    end

    res, err = redis:read_reply()
    if not res then
        return nil, err
    end

    redis:unsubscribe(channel)
    self:setKeepalive(redis)

    return res, err
end

function _M:doCommand(cmd, ...)
     
    if cmd == 'pipeline' then
        return self:pipeline(...)
    end

    if cmd == 'subscribe' then
        return self:subscribe(...)
    end

    if self._reqs then
        tapd(self._reqs, {cmd, ...})
        return
    end

    local redis, err = redisBase:new()
    if not redis then
        return nil, err
    end

    local ok, err = self:connect(redis)
    if not ok or err then
        return nil, err
    end

    local fun = redis[cmd]
    local result, err = fun(redis, ...)
    if not result or err then
        return nil, err
    end

    if isRedisNull(result) then
        result = nil
    end
    
    self:setKeepalive(redis)

    return result, err
end

return _M

