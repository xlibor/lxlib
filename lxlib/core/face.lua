
local _M = {
    _cls_  = ''
}

local app

local mt = {}

mt.__index = function(self, key)
    
    local t
    local nick = self.nick
    local isStatic = self.isStatic

    local stack = self.stack
    if stack then
        t = stack[key]
        if t then
            return function(...)
                local stackObj = self.stackObj

                return t(stackObj, ...)
            end
        end
    end

    return function(...)
        local obj = app:get(nick)
        local method = obj[key]

        if not method then
            error('unsupport method[' .. key .. ']')
        end
        if isStatic then
            return method(...)
        else
            return method(obj, ...)
        end
    end
end

mt.__call = function(self, ...)

    local nick = self.nick
    local isStatic = self.isStatic
    local defaultMethod = self.defaultMethod
    local obj = app:get(nick)

    if defaultMethod then
        local method = obj[defaultMethod]
        if isStatic then
            return method(...)
        else
            return method(obj, ...)
        end
    else
        return obj
    end
end

function _M:new(nick, isStatic, default, theApp)

    local this = {
        nick = nick,
        isStatic = isStatic,
        defaultMethod = default,
        static = false,
        stack = false,
        stackObj = false
    }
    
    app = theApp

    if app:getBag(nick) then
        local baseMt = app:getBaseMt(nick)
        this.__cls = baseMt.__cls
        this.static = baseMt.__staticBak or false
        if this.static then
            this.stack = baseMt.__stackBak or false
            if this.stack then
                this.stackObj = app:use(nick)
            end
        end
    end

    setmetatable(this, mt)

    return this
end

return _M

