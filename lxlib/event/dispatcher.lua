
local _M = {
    _cls_    = ''
}

local mt = { __index = _M }

local lx = require('lxlib')
local app, lf, tb, str, new = lx.kit()
local sfind = string.find

function _M:new()

    local this = {
        listeners     = {},
        firingList    = {},
         -- queueResolver = nil
    }

    setmetatable(this, mt)

    return this
end

function _M:listen(event, listener)

    local cls
    if sfind(event, '@') then
        cls, event = str.div(event, '@')
    end

    if cls then
        tb.mapd(self.listeners,
            cls, event, self:makeListener(listener)
        )
    else
        self.listeners[event] = self:makeListener(listener)
    end
end

function _M:hasListeners(cls, event)

    if self:getListeners(cls, event) then
        return true
    else
        return false
    end
end

function _M:subscribe(subscriber)

    subscriber = self:resolveSubscriber(subscriber)
    subscriber:subscribe(self)
end

function _M:resolveSubscriber(subscriber)

    if type(subscriber) == 'string' then
        return app:make(subscriber)
    end

    return subscriber
end
 
function _M:firing()

    return tb.last(self.firingList)
end

function _M:fire(obj, p1, ...)

    local cls, event
    if lf.isObj(obj) then
        cls = obj.__nick
        event = p1
    else
        event = obj
    end

    tapd(self.firingList, event)

    if cls and obj:__is 'shouldBroadcast' then
        self:broadcastEvent(obj)
    end
     
    local responses = {}

    local listeners = {}
    if cls then

        listeners = self:getListeners(cls, event)
    else
        listeners = self:getListeners(event)
    end

    if not listeners then

        return false
    end

    for _, listener in ipairs(listeners) do

        local eventInfo = {
            sender    = obj,
            name     = event,
            handled    = false
        }
        if cls then
            listener(eventInfo, ...)
        else
            listener(eventInfo, p1, ...)
        end

        tapd(responses, eventInfo)

        if eventInfo.handled then
            break
        end
    end

    tb.pop(self.firingList)
 
    return responses
end

_M.dispatch = _M.fire

function _M:getListeners(cls, event)

    local dict = self.listeners[cls]

    if not dict then
        return false
    end
    if not event then
        return dict
    else
        local list = dict[event]
        if not list then
            return dict['*']
        end
    end
end

function _M:makeListener(listener)

    local typ = type(listener)

    if typ == 'string' then
        return self:createClassListener(listener)
    elseif typ == 'table' then
        if #listener == 2 then
            return self:createClassListener(listener[1], listener[2])
        else 

        end
    else
        return listener
    end
end

function _M:createClassListener(listener, method)

    method = method or 'handle'
    
    return function(...)
        local obj = app:get(listener)
        local handler = obj[method]
        handler(obj, ...)
    end
end

function _M:broadcastEvent(event)
    -- todo
end

function _M:forget(event)

end

mt.__call = function(self) return self end

return _M

