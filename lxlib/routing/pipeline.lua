
local _M = {
    _cls_ = ''
}

local mt = { __index = _M }

local lx = require('lxlib')
local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        pipes = {},
        method = 'handle',
        filter = nil
    }

    setmetatable(this, mt)
    return this
end

function _M:send(passable)

    self.passable = passable
    
    return self
end

function _M:through(pipes)

    self.pipes = pipes

    return self
end

function _M:check(filter)

    self.filter = filter

    return self
end

function _M:via(method)

    self.method = method

    return self
end

function _M:deal(destination, ...)

    local pipes, method = self.pipes, self.method
    local passable = self.passable
    local filter = self.filter
    local firstSlice = self:getInitialSlice(destination)

    local cb = self:getSlice()
    local ret = firstSlice
    local vt, ifCall
    
    for k, v in pipes:kv(true) do
        ifCall = true
        if filter then
            if not filter(k, ...) then
                ifCall = false
            end
        end
        if ifCall then
            vt = type(v)
            if vt == 'function' then
                ret = cb(ret, v)
            else
                ret = cb(ret, k, v)
            end
        end
    end

    return ret(passable)
end

function _M:getInitialSlice(destination)
    
    return function(passable)
        destination(passable)
    end
end

function _M:getSlice()

    local method = self.method
    local defaultPassable = self.passable

    local ctx = app:ctx()

    return function(stack, pipe, params)
        return function(passable)
            local ret
            local pipeType = type(pipe)
            local obj, barKey, barPath
            local action

            if not passable then
                passable = defaultPassable
            end
            if pipeType == 'function' then
                ret = pipe(passable, stack)
            elseif pipeType == 'string' then
                obj = app:make(pipe)
                tapd(ctx.bars, obj)
                action = obj[method]
                if params and type(params) == 'table' then
                    ret = action(obj, passable, stack, unpack(params))
                else
                    ret = action(obj, passable, stack)
                end
            else
                error('unknown pipeType')
            end

            if ret then
                ctx:output(ret)
            end
        end
    end
end

return _M

