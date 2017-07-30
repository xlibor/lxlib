
local lx, _M, mt = oo{
    _cls_ = '',
    _bond_ = {
        'strable', 'jsonable', 'restorable',
        'countable', 'msgProvider'
    }
}

local app, lf, tb, str = lx.kit()

local sfind = string.find

function _M:new()

    local this = {
        msgs = {},
        format = ':msg'
    }
    
    return oo(this, mt)
end

function _M:ctor(msgs)

    msgs = msgs or {}
    for key, value in pairs(msgs) do
        self.msgs[key] = lf.needList(value)
    end
end

function _M:keys()

    return tb.keys(self.msgs)
end

function _M:add(key, msg)

    if self:isUnique(key, msg) then
        tb.mapd(self.msgs, key, msg)
    end
    
    return self
end

function _M.__:isUnique(key, msg)

    local msgs = self.msgs
    
    return not msgs[key] or not tb.inList(msgs[key], msg)
end

function _M:merge(msgs)

    if lf.isObj(msgs) and msgs:__is('msgProvider') then
        msgs = msgs:getMsgBag():getMsgs()
    end
    self.msgs = tb.deepMerge(self.msgs, msgs)
    
    return self
end

function _M:has(...)

    local keys, len = lf.needArgs(...)
    if len == 0 then
        
        return self:any()
    end

    for _, key in ipairs(keys) do
        if lf.empty(self:first(key)) then
            
            return false
        end
    end
    
    return true
end

function _M:hasAny(...)

    keys = lf.needArgs(...)

    for _, key in ipairs(keys) do
        if self:has(key) then
            
            return true
        end
    end
    
    return false
end

function _M:first(key, format)

    local msgs = key and self:get(key, format) or self:all(format)
    local firstMsg = tb.first(msgs, nil, '')
    
    return lf.isTbl(firstMsg) and tb.first(firstMsg) or firstMsg
end

function _M:get(key, format)

    if tb.has(self.msgs, key) then
        
        return self:transform(self.msgs[key], self:checkFormat(format), key)
    end
    if sfind(key, '%*') then
        
        return self:getMsgsForWildcardKey(key, format)
    end
    
    return {}
end

function _M.__:getMsgsForWildcardKey(key, format)

    return Col(self.msgs):filter(function(msgs, msgKey)

        return str.is(msgKey, key)
    end):map(function(msgs, msgKey)
        
        return self:transform(msgs, self:checkFormat(format), msgKey)
    end):all()
end

function _M:all(format)

    format = self:checkFormat(format)
    local all = {}
    for key, msgs in pairs(self.msgs) do
        all = tb.merge(all, self:transform(msgs, format, key))
    end
    
    return all
end

function _M:unique(format)

    return tb.unique(self:all(format))
end

function _M.__:transform(msgs, format, msgKey)

    local msg
    msgs = lf.needList(msgs)
    
    local replace = {':msg', ':key'}
    for i, msg in ipairs(msgs) do

        msg = str.replace(format, replace, {msg, msgKey})
        msgs[i] = msg
    end
    
    return msgs
end

function _M.__:checkFormat(format)

    return format or self.format
end

function _M:getMsgs()

    return self.msgs
end

function _M:getMsgBag()

    return self
end

function _M:getFormat()

    return self.format
end

function _M:setFormat(format)

    format = format or ':msg'
    self.format = format
    
    return self
end

function _M:isEmpty()

    return not self:any()
end

function _M:any()

    return self:count() > 0
end

function _M:count()

    return tb.count(self.msgs, 1)
end

function _M:toArr()

    local msgs = self:getMsgs()
    return msgs
end

function _M:toJson(options)

    options = options or 0
    
    return lf.jsen(self:toArr())
end

function _M:toStr()

    return self:toJson()
end

function _M:store()

    return self:toJson()
end

function _M:restore(data)

    data = data or {}
    self.msgs = {}
    for key, value in pairs(data) do
        self.msgs[key] = lf.needList(value)
    end
end

return _M

