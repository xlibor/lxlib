
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

local sfind = string.find

function _M:new()

    local this = {
        parsed = {}
    }
    
    return oo(this, mt)
end

function _M:parse(key)

    local parsed
    local segments
    
    if self.parsed[key] then
        
        return self.parsed[key]
    end
    
    if not sfind(key, '::', nil, true) then
        segments = str.split(key, '.')
        parsed = self:parseBasicSegments(segments)
    else
        parsed = self:parseNamespacedSegments(key)
    end
    
    self.parsed[key] = parsed

    return parsed
end

function _M.__:parseBasicSegments(segments)

    local group = segments[1]
    if #segments == 1 then
        
        return {nil, group, nil}
    else 
        item = str.join(tb.slice(segments, 2), '.')
        
        return {nil, group, item}
    end
end

function _M.__:parseNamespacedSegments(key)

    local namespace, item = str.div(key, '::')
    
    local itemSegments = str.split(item, '.')
    local groupAndItem = tb.slice(self:parseBasicSegments(itemSegments), 2)
    
    return tb.merge({namespace}, groupAndItem)
end

function _M:setParsed(key, parsed)

    self.parsed[key] = parsed
end

return _M

