
local lx, _M = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

function _M.__:replaceBetween(msg, attr, rule, params)

    return str.replace(msg, {':min', ':max'}, params)
end

function _M.__:replaceDateFormat(msg, attr, rule, params)

    return str.replace(msg, ':format', params[1])
end

function _M.__:replaceDifferent(msg, attr, rule, params)

    return self:replaceSame(msg, attr, rule, params)
end

function _M.__:replaceDigits(msg, attr, rule, params)

    return str.replace(msg, ':digits', params[1])
end

function _M.__:replaceDigitsBetween(msg, attr, rule, params)

    return self:replaceBetween(msg, attr, rule, params)
end

function _M.__:replaceMin(msg, attr, rule, params)

    return str.replace(msg, ':min', params[1])
end

function _M.__:replaceMax(msg, attr, rule, params)

    return str.replace(msg, ':max', params[1])
end

function _M.__:replaceIn(msg, attr, rule, params)

    local parameter
    for _, parameter in pairs(params) do
        parameter = self:getDisplayableValue(attr, parameter)
    end
    
    return str.replace(msg, ':values', str.join(params, ', '))
end

function _M.__:replaceNotIn(msg, attr, rule, params)

    return self:replaceIn(msg, attr, rule, params)
end

function _M.__:replaceInArray(msg, attr, rule, params)

    return str.replace(msg, ':other', self:getDisplayableAttr(params[1]))
end

function _M.__:replaceMimetypes(msg, attr, rule, params)

    return str.replace(msg, ':values', str.join(params, ', '))
end

function _M.__:replaceMimes(msg, attr, rule, params)

    return str.replace(msg, ':values', str.join(params, ', '))
end

function _M.__:replaceRequiredWith(msg, attr, rule, params)

    return str.replace(msg, ':values', str.join(self:getAttrList(params), ' / '))
end

function _M.__:replaceRequiredWithAll(msg, attr, rule, params)

    return self:replaceRequiredWith(msg, attr, rule, params)
end

function _M.__:replaceRequiredWithout(msg, attr, rule, params)

    return self:replaceRequiredWith(msg, attr, rule, params)
end

function _M.__:replaceRequiredWithoutAll(msg, attr, rule, params)

    return self:replaceRequiredWith(msg, attr, rule, params)
end

function _M.__:replaceSize(msg, attr, rule, params)

    return str.replace(msg, ':size', params[1])
end

function _M.__:replaceRequiredIf(msg, attr, rule, params)

    params[1] = self:getDisplayableValue(params[1], tb.get(self.data, params[1]))
    params[1] = self:getDisplayableAttr(params[1])
    
    return str.replace(msg, {':other', ':value'}, params)
end

function _M.__:replaceRequiredUnless(msg, attr, rule, params)

    local other = self:getDisplayableAttr(tb.shift(params))
    
    return str.replace(msg,
        {':other', ':values'},
        {other, str.join(params, ', ')}
    )
end

function _M.__:replaceSame(msg, attr, rule, params)

    return str.replace(msg, ':other', self:getDisplayableAttr(params[1]))
end

function _M.__:replaceBefore(msg, attr, rule, params)

    if not strtotime(params[1]) then
        
        return str.replace(msg, ':date', self:getDisplayableAttr(params[1]))
    end
    
    return str.replace(msg, ':date', params[1])
end

function _M.__:replaceBeforeOrEqual(msg, attr, rule, params)

    return self:replaceBefore(msg, attr, rule, params)
end

function _M.__:replaceAfter(msg, attr, rule, params)

    return self:replaceBefore(msg, attr, rule, params)
end

function _M.__:replaceAfterOrEqual(msg, attr, rule, params)

    return self:replaceBefore(msg, attr, rule, params)
end

return _M

