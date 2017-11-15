
local _M = {
    _cls_     = ''
}

local mt = { __index = _M }

local lx = require('lxlib')
local app = lx.app()
local tb = lx.tb

function _M:ctor()

    self.__events = {}
end

function _M:getEvents()

    return self.__events
end

function _M:on(name, handler, data, append)

    local events = self.__events
 
    if append or not events[name] then
        events[name] = {{handler, data}}
    else
        tb.unshift(events[name], {handler, data})
    end
end

function _M:off(name)

    if name then
        local events = self.__events
        local event = events[name]

        if event then
            events[name] = nil
        end
    else
        self.__events = {}
    end
end

function _M:fire(name, ...)

    local events = self.__events
    if not events then
        error('no events')
    end
    local eventDef = events[name]

    if eventDef then

        local eventArgs = {
            sender    = self,
            name     = name,
            handled    = false
        }
  
        for _, handler in ipairs(eventDef) do
            eventArgs.data = handler[2]
            self:_doFire(handler[1], eventArgs, ...)
            if eventArgs.handled then
                return
            end
        end
    end
end

function _M:_doFire(cls, ...)

    local typ = type(cls)
    local obj
    
    if typ == 'function' then
        return cls(...)
    elseif typ == 'string' then
        obj = app:make(cls)
        obj:handle(...)
    elseif typ == 'table' then
        if #cls > 0 then
            local nick, method = cls[1], cls[2]
            if type(nick) == 'string' then
                obj = app:make(nick)
            elseif type(nick) == 'table' then
                obj = nick
            end
 
            return obj[method](obj, ...) 
        end
    end
end

return _M

