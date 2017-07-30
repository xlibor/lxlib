
local lx, _M, mt = oo{
    _cls_ = '',
    _bond_ = 'logFormatterBond',
    _static_ = {
        simpleDate = '%Y-%m-%d %H:%M:%S',
    }
}

local app, lf, tb, str = lx.kit()
local json = lx.json

local static

function _M._init_(this)

    static = this.static
end

function _M:new()

    local this = {
    }
    
    return oo(this, mt)
end

-- @param string|null dateFormat The format of the timestamp: one supported by DateTime::format

function _M:ctor(dateFormat)

    self.dateFormat = dateFormat or static.simpleDate

end

-- {@inheritdoc}

function _M:format(record)

    return self:normalize(record)
end

-- {@inheritdoc}

function _M:formatBatch(records)

    for key, record in pairs(records) do
        records[key] = self:format(record)
    end
    
    return records
end

function _M.__:normalize(data)

    local value
    local count
    local normalized
    local dataType = type(data)

    if dataType == 'nil' or lf.isScalar(data) then
        if lf.isFloat(data) then

        end
        
        return data
    end

    if dataType == 'table' then
        if data.__cls then
            if data:__is('datetime') then

                return data:format(self.dateFormat)
            end

            if data:__is('exception') then
                
                return self:normalizeException(data)
            end

            if data:__is('strable') then
                value = data:toStr()
            elseif data:__is('jsonable') then
                value = self:toJson(data, true)
            end
            
            return str.fmt("[object] (%s: %s)", data.__cls, value)
        else
            normalized = {}
            count = 0
            for key, value in pairs(data) do
                count = count + 1
                if count >= 1000 then
                    normalized['...'] = 'Over 1000 items aborting normalization'
                    break
                end
                normalized[key] = self:normalize(value)
            end
            
            return normalized
        end
    end

    return '[unknown(' .. dataType .. ')]'
end

function _M.__:normalizeException(e)

    if not e:__is('exception') then

        lx.throw('invalidArgumentException', 'exception/throwable expected, got ' .. e.__cls)
    end

    local data = {
        class = e.__cls,
        message = e:getMsg(),
        code = e:getCode(),
        file = e:getFile() .. ':' .. e:getLine()
    }

    local trace = e:getTrace()

    local previous = e:getPrevious()
    if previous then
        data['previous'] = self:normalizeException(previous)
    end
    
    return data
end

-- Return the JSON representation of a value
-- @param  mixed             data
-- @param  bool              ignoreErrors
-- @return string

function _M.__:toJson(data, ignoreErrors)

    -- suppress json_encode errors since it's twitchy with some inputs
    if ignoreErrors then
        
        return json.safeEncode(data)
    else
        return json.encode(data)
    end
end

return _M

