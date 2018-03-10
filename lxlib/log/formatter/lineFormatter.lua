
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'logNormalizerFormatter',
    _static_ = {
        simpleFormat = "[#datetime#] #channel#.#level_name#: #message# #context# #extra#\n"
    }
}

local app, lf, tb, str = lx.kit()
local sfind = string.find

local static

function _M._init_(this)

    static = this.static
end

function _M:new()

    local this = {
    }
    
    return oo(this, mt)
end

-- @param string|null       format                     The format of the message
-- @param string|null       dateFormat                 The format of the timestamp: one supported by DateTime::format
-- @param bool|null         allowInlineLineBreaks      Whether to allow inline line breaks in log entries
-- @param bool|null         ignoreEmptyContextAndExtra

function _M:ctor(format, dateFormat, allowInlineLineBreaks, ignoreEmptyContextAndExtra)

    self._format = format or static.simpleFormat
    self.allowInlineLineBreaks = allowInlineLineBreaks or false
    self.ignoreEmptyContextAndExtra = lf.needTrue(ignoreEmptyContextAndExtra)
    
    self.__skip = true
    self:__super(_M, 'ctor', dateFormat)

end

function _M:includeStacktraces(include)

    include = lf.needTrue(include)
    self.includeStacktraces = include
    if self.includeStacktraces then
        self.allowInlineLineBreaks = true
    end
end

function _M:allowInlineLineBreaks(allow)

    allow = lf.needTrue(allow)
    self.allowInlineLineBreaks = allow
end

function _M:ignoreEmptyContextAndExtra(ignore)

    ignore = lf.needTrue(ignore)
    self.ignoreEmptyContextAndExtra = ignore
end

-- {@inheritdoc}

function _M:format(record)

    local vars = self:__super(_M, 'format', record)
    local output = self._format

    for var, val in pairs(vars.extra) do
        if sfind(output, '#extra.' .. var .. '#', nil, true) then
            output = str.replace(output, '#extra.' .. var .. '#', self:stringify(val), true)
            vars.extra[var] = nil
        end
    end
    for var, val in pairs(vars.context) do
        if sfind(output, '#context.' .. var .. '#', nil, true) then
            output = str.replace(output, '#context.' .. var .. '#', self:stringify(val), true)
            vars.context[var] = nil
        end
    end
    if self.ignoreEmptyContextAndExtra then
        if lf.isEmpty(vars.context) then
            vars.context = nil
            output = str.replace(output, '#context#', '', true)
        end
        if lf.isEmpty(vars.extra) then
            vars.extra = nil
            output = str.replace(output, '#extra#', '', true)
        end
    end
    for var, val in pairs(vars) do
        if sfind(output, '#' .. var .. '#', nil, true) then
            if var == 'message' then
                val = str.lregQuote(val)
            end
            output = str.replace(output, '#' .. var .. '#', self:stringify(val), true)
        end
    end

    -- remove leftover #extra.xxx# and #context.xxx# if any
    -- if str.strpos(output, '#') then
    --     output = str.rereplace(output, '/#(?:extra|context)\\..+?#/', '')
    -- end
    
    return output
end

function _M:formatBatch(records)

    local message = ''
    for _, record in ipairs(records) do
        message = message .. self:format(record)
    end
    
    return message
end

function _M:stringify(value)

    return self:replaceNewlines(self:convertToString(value))
end

function _M.__:normalizeException(e)

    if not e:__is('exception') then
        lx.throw('invalidArgumentException', 'exception expected, got ' .. e.__cls)
    end

    local previousText = ''
    local previous = e:getPrevious()
    if previous then
        repeat
            previousText = previousText .. ', ' .. previous.__cls .. '(code: ' .. previous:getCode() .. '): ' .. previous:getMsg() .. ' at ' .. previous:getFile() .. ':' .. previous:getLine()
            previous = previous:getPrevious()
        until not previous
    end
    local s = '[object] (' .. e.__cls .. '(code: ' .. e:getCode() .. '): ' .. e:getMsg() .. ' at ' .. e:getFile() .. ':' .. e:getLine() .. previousText .. ')'
    if self.includeStacktraces then
        s = s .. "\n[stacktrace]\n" .. e:getTraceAsString()
    end
    
    return s
end

function _M.__:convertToString(data)

    if nil == data or lf.isBool(data) then
        
        return tostring(data)
    end
    if lf.isScalar(data) then
        
        return tostring(data)
    end
    if lf.isTbl(data) then
        
        return self:toJson(data, true)
    end
    
    return str.replace(lf.jsen(data), '\\/', '/')
end

function _M.__:replaceNewlines(s)

    if self.allowInlineLineBreaks then
        
        return s
    end
    
    return str.replace(s, {"\r\n", "\r", "\n"}, ' ')
end

return _M

