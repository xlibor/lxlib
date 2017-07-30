
local _M = {
    _cls_ = ''
}

local mt = { __index = _M }

local lx = require('lxlib')
local app, lf, tb, str = lx.kit()
local throw = lx.throw

local smatch, sfind, ssub = string.match, string.find, string.sub

function _M:new(action, ...)
    
    local this = {
        tryAction     = action,
        tryParams     = {...},
        catchStack     = {},
        catchPos     = 1,
        caught         = false,
        cancel         = false
    }

    setmetatable(this, mt)

    return this
end

function _M:she()

    local try = function( ... )
        return self:try(...)
    end
    local catch = function( ... )
        return self:catch(...)
    end
    local final = function( ... )
        return self:final(...):run()
    end
 
    return try, catch, final
end

function _M:reset()

    self.tryAction = nil
    self.tryParams = {}
    self.catchStack = {}
    self.catchPos = 1
    self.caught = false
    self.cancel = false
    self.curException = nil
end

function _M:try(action, ...)

    self:reset()
    self.tryAction = action
    self.tryParams = {...}
end

function _M:catch(p1, p2, p3)

    local catchInfo = {}
    if p2 then
        catchInfo.etype = p1; catchInfo.action = p2
        if p3 then
            catchInfo.bubble = true
        end
    else
        catchInfo.etype = 'exception'; catchInfo.action = p1
    end

    tapd(self.catchStack, catchInfo)

    return self
end

function _M:final(action)

    self.finalAction = action
 
    return self
end

function _M:updateExcpLevel(num)

    local ctx = ngx.ctx

    if not ctx then return end

    local excpLevel = ctx.excpLevel
    if excpLevel then
        excpLevel = excpLevel + num
        ctx.excpLevel = excpLevel
    else
        excpLevel = 1
        ctx.excpLevel = excpLevel
    end

end

function _M:run(cancel)

    self.cancel = cancel

    if not cancel then
        self:updateExcpLevel(1)
    end

    local ok, p1, p2, p3, p4, p5 = self:runTry()

    if not cancel then 
        if ok then
            self:runFinal()
            return true, p1, p2, p3, p4, p5
        else
            self:runCatch()
        end
     
        self:runFinal()
 
        return false
    else
        return true, p1, p2, p3, p4, p5
    end

end

function _M:runFinal()

    local finalAction = self.finalAction
    if finalAction then
        finalAction(self.curException, self.caught)
    else

    end

    self:updateExcpLevel(-1)

    self:checkUncaughtException()

end

function _M:checkUncaughtException()

    local ctx = ngx.ctx
    local excpLevel = ctx.excpLevel
    local uncaughtException = ctx.uncaughtException

    if uncaughtException and excpLevel > 0 then
        throw(uncaughtException)
    end
end

function _M:makeException(err, trace)

    local e
    local excpType = 'errorException'
    local file, line, msg, code, detail

    file, line, detail = smatch(err, "(%S*%.lua)%:(%d+):(.*)[\n]?")
    line = tonumber(line)
    if not line then
        line = smatch(trace, "%]:(%d+):")
        line = tonumber(line)
        if not line then
            file, line = smatch(trace, "(%S*%.lua):(%d+):")
            line = tonumber(line)
        end
        detail = smatch(err, ":%d+:(.*)[\n]?") or err
    end
 
    if not file then
        file = smatch(err, "%[string \"%-%-(.*)\"%]")
    end

    if sfind(err, "%[- @type:") then 
        local defedType = smatch(err, "%[%- @type:(%w+) %-%]")
        if defedType then 
            excpType = defedType
        end
    else
        msg = detail
    end

    if not file then 
        file = 'unknown'
        msg = err
    end
 
    local ctx = ngx.ctx
    local tempException = ctx.tempException

    if tempException then 
        e = tempException
        ctx.tempException = nil
        if not e.file then
            e.file = file; e.line = line; e.trace = trace
        end
    else

        e = self:makeDefinedException(excpType, msg, code)
        e.file = file; e.line = line; e.trace = trace
    end
     
    self.curException = e
end

function _M:makeDefinedException(excpType, msg, code)

    local sign = ssub(msg, 2, 7)
    if sign == 'module' then
        local modName = smatch(msg, 'module \'(.*)\' not found')
        if modName then
            excpType = 'moduleNotFoundException'
        end
    end

    return app:make(excpType, msg, code)

end

function _M:runTry()

    local action = self.tryAction
    local actionType = type(action)
     
    if self.cancel then 
        if actionType == 'table' then
            local obj, method = action[1], action[2]
            return obj[method](obj, unpack(self.tryParams))
        elseif actionType == 'function' then
            return action(unpack(self.tryParams))
        end

        return true
    end

    local tErr,tTrace
    local ok, p1,p2,p3,p4,p5 = xpcall(
        (function() 

        if actionType == 'table' then
            local obj, method = action[1], action[2]
            return obj[method](obj, unpack(self.tryParams))
        elseif actionType == 'function' then
            return action(unpack(self.tryParams))
        end

        end), 
        function(_err)
            tErr = _err
            tTrace = debug.traceback('', 2)
        end
    )
    
    if not ok then
        self:makeException(tErr, tTrace)

        return false
    else
        local ctx = ngx.ctx
        local uncaughtException = ctx.uncaughtException
        if uncaughtException then
            self.curException = uncaughtException
            return false
        end

        return true,p1,p2,p3,p4,p5
    end

end

function _M:runCatch()

    local etype, action, bubble

    for _, v in ipairs(self.catchStack) do
        etype, action, bubble = v.etype, v.action, v.bubble

        if self.curException:__is(etype) then

            self.caught = true
            if self:runCatchAction(action) or bubble then
                return
            else

            end
        end
    end

    if self.curException then
        local ctx = ngx.ctx
        ctx.uncaughtException = self.curException
    end
end

function _M:runCatchAction(action)

    local tErr, tTrace
    local ok = xpcall(
        (function() 
            return action(self.curException)
        end),
        function(_err)
            tErr = _err
            tTrace = debug.traceback('', 2)
        end
    )

    if not ok then
        self:makeException(tErr, tTrace)
        return false
    else
        ngx.ctx.uncaughtException = nil
        return true
    end

end

function _M:retry()

    return self:run()
end

return _M

