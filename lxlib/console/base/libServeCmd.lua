
local lx, _M = oo{
    _cls_ = '',
    _ext_ = 'command'
}

local app, lf, tb, str = lx.kit()
local fs = lx.fs

function _M:ctor()

end

function _M.__:getConfPath()

    local pubPath = self.pubPath
    local confPath = pubPath..'/nginx.conf'

    return confPath
end

function _M.__:preCheck()

    local pubPath = self.pubPath
    local confPath = pubPath..'/nginx.conf'

    if not fs.exists(confPath) then
        self:warn('not set nginx.conf in lxpub')
        return false
    end

    local envPath = pubPath..'/env.json'
    if not fs.exists(envPath) then
        self:warn('env.json not exists')
        return false
    end


    local logPath = pubPath..'/log'
    if not fs.exists(logPath) then
        fs.makeDir(logPath)
    end

    return true
end

function _M:reload()

    if not self:preCheck() then return end

    self:info(lf.run('openresty -s reload -c '..self:getConfPath()))
end

function _M:stop()

    if not self:preCheck() then return end

    self:info(lf.run('openresty -s stop -c '..self:getConfPath()))
end

function _M:quit()

    if not self:preCheck() then return end
    
    self:info(lf.run('openresty -s quit -c '..self:getConfPath()))
end

function _M:start()

    if not self:preCheck() then return end

    self:info(lf.run('openresty -c '..self:getConfPath()))
end

return _M

