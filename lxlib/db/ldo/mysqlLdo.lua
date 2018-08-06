
local lx, _M, mt = oo{ 
    _cls_    = '',
    _ext_    = 'lxlib.db.ldo.ldo'
}

local app, lf, tb, str = lx.kit()

local mysql = require('lxlib.resty.mysql')

local timeout_subsequent_ops = 5000 -- 5 sec
local max_idle_timeout = 10000 -- 10 sec
local max_packet_size = 1024 * 1024 -- 1MB
local default_pool_size = 10
local STATE_CONNECTED, STATE_COMMAND_SENT = 1, 2

function _M:new(config)

    local this = {
        config = config, 
        inTrans = false
    }

    return oo(this, mt)
end

local function db_execute(config, db, sql, rowAsList, inTrans)

    local res, err, errno, sqlstate = db:query(sql, nil, rowAsList)
    if not res then
        if not errno then errno = '' end
        if not sqlstate then sqlstate = '' end
        error("bad mysql result: " .. err .. ": " .. errno .. " " .. sqlstate)
    end

    return res
end

local function mysqlConnect(config)
 
    local db, err = mysql:new()
    if not db then error("failed to instantiate mysql: " .. err) end

    db:set_timeout(timeout_subsequent_ops)
 
    local ok, err, errno, sqlstate = db:connect(config)
    if not ok then
        errno = errno or ''
        sqlstate = sqlstate or ''
        error("failed to connect to mysql;" .. err .. "," .. errno .. " " .. sqlstate)
    end

    if config.modes then
        local modes = str.join(config.modes, ',')
        db:query("set session sql_mode='" .. modes .. "'")
    elseif config.strict then
        db:query("set session sql_mode='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION'")
    elseif lf.isFalse(config.strict) then
        db:query("set session sql_mode='NO_ENGINE_SUBSTITUTION'")
    end

    return db
end

local function mysql_keepalive(db, config)

    local ok, err = db:set_keepalive(max_idle_timeout, config.poolSize or default_pool_size)
    if not ok then
        err = tostring(err) or 'unknown'
        error("failed to set mysql keepalive: " .. err)
    end
end

function _M:ctor(config)

    app:overWith(function()
        self:over()
    end)

    local db = mysqlConnect(config)
    if not db then

        error('connect db failed')
    else
        self.db = db
    end

end

function _M:over()

    local config = self.config
    local db = self.db

    if db then
        mysql_keepalive(db, config)
        self.db = nil
    end
end

function _M.__:checkDb()

    local db = self.db
    local config = self.config
    if db then
        if db.state ~= STATE_CONNECTED then
            db = mysqlConnect(config)
            self.db = db
        end
    else
        db = mysqlConnect(config)
        self.db = db
    end
end

function _M:query(sql, rowAsList)

    return self:exec(sql, rowAsList)
end

function _M:exec(sql, rowAsList)

    self:checkDb()
    local config = self.config
    local db = self.db
    local res = db_execute(config, db, sql, rowAsList)
    if not self.inTrans then
        mysql_keepalive(db, config)
        self.db = nil
    end

    return res
end

function _M:beginTransaction()

    if self.inTrans then
        error('already in trans')
    else
        self.inTrans = true
        local res = self:exec('start transaction;')
        if res then
            return true
        else
            self.inTrans = false
            return false
        end
    end
end

function _M:commit()

    if not self.inTrans then
        error('not in a trans')
    else
        local res = self:exec('COMMIT;')
        self.inTrans = false
        return res and true or false
    end
end

function _M:rollback()

    local res = self:exec('ROLLBACK;')
    self.inTrans = false
    
    return res and true or false
end

return _M

