
local lx, _M = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()
local sfind = string.find 

local ValidationData = lx.use('lxlib.validation.validationData')

function _M.__:validateAccepted(attr, value)

    local acceptable = {'yes', 'on', '1', 1, true, 'true'}
    
    return self:validateRequired(attr, value)
        and tb.inList(acceptable, value, true)
end

function _M.__:validateActiveUrl(attr, value)

    if not lf.isStr(value) then
        
        return false
    end
    local url = lf.parseUrl(value, 'host')
    if url then
        return true
    end
    
    return false
end

function _M.__:validateBail()

    return true
end

function _M.__:validateBefore(attr, value, params)

    self:requireParamCount(1, params, 'before')
    
    return self:compareDates(attr, value, params, '<')
end

function _M.__:validateBeforeOrEqual(attr, value, params)

    self:requireParamCount(1, params, 'before_or_equal')
    
    return self:compareDates(attr, value, params, '<=')
end

function _M.__:validateAfter(attr, value, params)

    self:requireParamCount(1, params, 'after')
    
    return self:compareDates(attr, value, params, '>')
end

function _M.__:validateAfterOrEqual(attr, value, params)

    self:requireParamCount(1, params, 'after_or_equal')
    
    return self:compareDates(attr, value, params, '>=')
end

function _M.__:compareDates(attr, value, params, operator)

    if not lf.isStr(value) and not lf.isNum(value) and not value:__is('dateTimeBond') then
        
        return false
    end
    local t = params[1]
    local format = self:getDateFormat(attr)
    if format then
        
        return self:checkDateTimeOrder(format, value, self:getValue(t) or t, operator)
    end
    local date = self:getDateTimestamp(t)
    if not (date) then
        date = self:getDateTimestamp(self:getValue(t))
    end
    
    return self:compare(self:getDateTimestamp(value), date, operator)
end

function _M.__:getDateFormat(attr)

    local result = self:getRule(attr, 'DateFormat')
    if result then
        
        return result[2][1]
    end
end

function _M.__:getDateTimestamp(value)

    return value:__is('dateTimeBond') and value:getTimestamp() or strtotime(value)
end

function _M.__:checkDateTimeOrder(format, first, second, operator)

    first = self:getDateTimeWithOptionalFormat(format, first)
    second = self:getDateTimeWithOptionalFormat(format, second)
    
    return first and second and self:compare(first, second, operator)
end

function _M.__:getDateTimeWithOptionalFormat(format, value)

    local date = DateTime.createFromFormat(format, value)
    if date then
        
        return date
    end

    return lf.filter(value, 'datetime')
end

function _M.__:validateAlpha(attr, value)

    return lf.isStr(value) and str.rematch(value, [[^[\pL\pM]+$]], 'ijou')
end

function _M.__:validateAlphaDash(attr, value)

    if not lf.isStr(value) and not lf.isNum(value) then
        
        return false
    end
    
    return str.rematch(value, [[^[\\pL\\pM\\pN_-]+$]], 'ijou')
end

function _M.__:validateAlphaNum(attr, value)

    if not lf.isStr(value) and not lf.isNum(value) then
        
        return false
    end

    return str.rematch(value, [[^[\pL\pM\pN]+$]], 'ijou')
end

function _M.__:validateArray(attr, value)

    return lf.isTbl(value)
end

function _M.__:validateBetween(attr, value, params)

    self:requireParamCount(2, params, 'between')
    local size = self:getSize(attr, value)
    local left, right = tonumber(params[1]), tonumber(params[2])

    return size >= left and size <= right
end

function _M.__:validateBoolean(attr, value)

    local acceptable = {true, false, 0, 1, '0', '1'}
    
    return tb.inList(acceptable, value, true)
end

function _M.__:validateConfirmed(attr, value)

    return self:validateSame(attr, value, {attr .. '_confirmation'})
end

function _M.__:validateDate(attr, value)

    if value:__is('dateTime') then
        
        return true
    end
    if not lf.isStr(value) and not lf.isNum(value) or strtotime(value) == false then
        
        return false
    end
    local date = date_parse(value)
    
    return checkdate(date['month'], date['day'], date['year'])
end

function _M.__:validateDateFormat(attr, value, params)

    self:requireParamCount(1, params, 'date_format')
    if not lf.isStr(value) and not lf.isNum(value) then
        
        return false
    end
    local date = DateTime.createFromFormat(params[1], value)
    
    return date and date:format(params[1]) == value
end

function _M.__:validateDifferent(attr, value, params)

    self:requireParamCount(1, params, 'different')
    local other = tb.get(self.data, params[1])
    
    return other and value ~= other
end

function _M.__:validateDigits(attr, value, params)

    self:requireParamCount(1, params, 'digits')
    
    return not str.rematch(value, '/[^0-9]/') and str.len(tostring(value)) == params[1]
end

function _M.__:validateDigitsBetween(attr, value, params)

    self:requireParamCount(2, params, 'digits_between')
    local length = str.len(tostring(value))
    
    return not str.rematch(value, '[^0-9]') and length >= params[1] and length <= params[2]
end

function _M.__:validateDimensions(attr, value, params)

    local sizeDetails = getimagesize(value:getRealPath())
    if not self:isValidFileInstance(value) or not (sizeDetails) then
        
        return false
    end
    self:requireParamCount(1, params, 'dimensions')
    local width, height = unpack(sizeDetails)
    params = self:parseNamedParams(params)
    if self:failsBasicDimensionChecks(params, width, height) or self:failsRatioCheck(params, width, height) then
        
        return false
    end
    
    return true
end

function _M.__:failsBasicDimensionChecks(params, width, height)

    return (params['width'] and params['width'] ~= width)
        or (params['min_width'] and params['min_width'] > width)
        or (params['max_width'] and params['max_width'] < width)
        or (params['height'] and params['height'] ~= height)
        or (params['min_height'] and params['min_height'] > height)
        or (params['max_height'] and params['max_height'] < height)
end

function _M.__:failsRatioCheck(params, width, height)

    if not params['ratio'] then
        
        return false
    end
    local numerator, denominator = unpack(tb.replace({1, 1},
            tb.filter(fmt(params['ratio'], '%f/%d'))
    ))
    
    return numerator / denominator ~= width / height
end

function _M.__:validateDistinct(attr, value, params)

    local attrName = self:getPrimaryAttr(attr)
    local attrData = ValidationData.extractDataFromPath(
        ValidationData.getLeadingExplicitAttrPath(attrName), self.data
    )
    local pattern = str.replace(str.pregQuote(attrName, '#'), '\\*', '[^.]+')
    local data = tb.where(tb.dot(attrData), function(value, key)
        
        return key ~= attr and str.rematch(key, '#^' .. pattern .. '\\z#u')
    end)
    
    return not tb.inList(tb.values(data), value)
end

function _M.__:validateEmail(attr, value)

    return lf.filter(value, 'email')
end

function _M.__:validateExists(attr, value, params)

    self:requireParamCount(1, params, 'exists')
    local connection, table = unpack(self:parseTable(params[1]))
    
    local column = self:getQueryColumn(params, attr)
    local expected = lf.isTbl(value) and #value or 1
    
    return self:getExistCount(connection, table, column, value, params) >= expected
end

function _M.__:getExistCount(connection, table, column, value, params)

    local verifier = self:getVerifierFor(connection)
    local extra = self:getExtraConditions(tb.values(tb.slice(params, 2)))
    
    local currentRule = self.currentRule
    if lf.isA(currentRule, 'lxlib.validation.rules.exists') then
        extra = tb.merge(extra, currentRule:queryCallbacks())
    end
    
    return lf.isTbl(value)
        and verifier:getMultiCount(table, column, value, extra)
        or verifier:getCount(table, column, value, nil, nil, extra)
end

function _M.__:validateUnique(attr, value, params)

    self:requireParamCount(1, params, 'unique')
    local connection, table = unpack(self:parseTable(params[1]))
    
    local column = self:getQueryColumn(params, attr)
    local idColumn, id
    if params[3] then
        idColumn, id = unpack(self:getUniqueIds(params))
    end
    
    local verifier = self:getVerifierFor(connection)
    local extra = self:getUniqueExtra(params)

    local currentRule = self.currentRule
    if lf.isA(currentRule, 'lxlib.validation.rules.unique') then
        extra = tb.merge(extra, currentRule:queryCallbacks())
    end
    
    return verifier:getCount(table, column, value, id, idColumn, extra) == 0
end

function _M.__:getUniqueIds(params)

    local idColumn = params[4] or 'id'
    
    return {idColumn, self:prepareUniqueId(params[3])}
end

function _M.__:prepareUniqueId(id)

    if str.rematch(id, '\\[(.*)\\]', matches) then
        id = self:getValue(matches[1])
    end
    if str.lower(id) == 'null' then
        id = nil
    end
    if lf.isNum(id) ~= false then
        id = tonumber(id)
    end
    
    return id
end

function _M.__:getUniqueExtra(params)

    if params[5] then
        
        return self:getExtraConditions(tb.slice(params, 4))
    end
    
    return {}
end

function _M.__:parseTable(table)

    return sfind(table, '%.') and str.split(table, '.', 2) or {nil, table}
end

function _M.__:getQueryColumn(params, attr)

    return params[2] and params[2] ~= 'null'
        and params[2] or self:guessColumnForQuery(attr)
end

function _M:guessColumnForQuery(attr)

    local last = str.last(attr, '.')
    if tb.inList(tb.collapse(self.implicitAttrs), attr)
        and not lf.isNum(last) then
        
        return last
    end
    
    return attr
end

function _M.__:getExtraConditions(segments)

    local extra = {}
    local count = #segments
    for i = 1, count + 1, 2 do
        extra[segments[i]] = segments[i + 1]
    end
    
    return extra
end

function _M.__:validateFile(attr, value)

    return self:isValidFileInstance(value)
end

function _M.__:validateFilled(attr, value)

    if tb.has(self.data, attr) then
        
        return self:validateRequired(attr, value)
    end
    
    return true
end

function _M.__:validateImage(attr, value)

    return self:validateMimes(attr, value, {'jpeg', 'jpg', 'png', 'gif', 'bmp', 'svg'})
end

function _M.__:validateIn(attr, value, params)

    if lf.isTbl(value) and self:hasRule(attr, 'Array') then
        for _, element in pairs(value) do
            if lf.isTbl(element) then
                
                return false
            end
        end
        
        return #tb.diff(value, params) == 0
    end
    
    return not lf.isTbl(value) and tb.inList(params, tostring(value))
end

function _M.__:validateInArray(attr, value, params)

    self:requireParamCount(1, params, 'in_array')
    local explicitPath = ValidationData.getLeadingExplicitAttrPath(params[1])
    local attrData = ValidationData.extractDataFromPath(explicitPath, self.data)
    local otherValues = tb.where(tb.dot(attrData), function(value, key)
        
        return str.is(params[1], key)
    end)
    
    return tb.inList(otherValues, value)
end

function _M.__:validateInteger(attr, value)

    return lf.isIntStr(value)
end

function _M.__:validateIp(attr, value)

    return lf.filter(value, 'ip') ~= false
end

function _M.__:validateIpv4(attr, value)

    return lf.filter(value, 'ip', 'ipv4') ~= false
end

function _M.__:validateIpv6(attr, value)

    return lf.filter(value, 'ip', 'ipv6') ~= false
end

function _M.__:validateJson(attr, value)

    if not lf.isScalar(value) and not value:__is('strable') then
        
        return false
    end

    return lf.isJson(value)
end

function _M.__:validateMax(attr, value, params)

    self:requireParamCount(1, params, 'max')
    if lf.isA(value, 'uploadedFile') and not value:isValid() then
        
        return false
    end
    
    local param = tonumber(params[1])
    return self:getSize(attr, value) <= param
end

function _M.__:validateMimes(attr, value, params)

    if not self:isValidFileInstance(value) then
        
        return false
    end

    return value.path and tb.inList(params, value:guessExtension())
end

function _M.__:validateMimetypes(attr, value, params)

    if not self:isValidFileInstance(value) then
        
        return false
    end

    return value:getPath() ~= '' and tb.inList(params, value:getMimeType())
end

function _M.__:validateMin(attr, value, params)

    self:requireParamCount(1, params, 'min')
    local param = tonumber(params[1])

    return self:getSize(attr, value) >= param
end

function _M.__:validateNullable()

    return true
end

function _M.__:validateNotIn(attr, value, params)

    return not self:validateIn(attr, value, params)
end

function _M.__:validateNumeric(attr, value)

    return lf.isNumStr(value)
end

function _M.__:validatePresent(attr, value)

    return tb.has(self.data, attr)
end

function _M.__:validateRegex(attr, value, params)

    if not lf.isStr(value) and not lf.isNum(value) then
        
        return false
    end
    self:requireParamCount(1, params, 'regex')
    
    return str.rematch(value, params[1])
end

function _M.__:validateRequired(attr, value)

    if not value then
        
        return false
    elseif lf.isStr(value) and str.trim(value) == '' then
        
        return false
    elseif lf.isA(value, 'countable') and #value < 1 then
        
        return false
    elseif lf.isA(value, 'file') then
        
        return tostring(value:getPath()) ~= ''
    end
    
    return true
end

function _M.__:validateRequiredIf(attr, value, params)

    self:requireParamCount(2, params, 'required_if')
    local other = tb.get(self.data, params[1])
    local values = tb.slice(params, 1)
    if lf.isBool(other) then
        values = self:convertValuesToBoolean(values)
    end
    if tb.inList(values, other) then
        
        return self:validateRequired(attr, value)
    end
    
    return true
end

function _M.__:convertValuesToBoolean(values)

    return tb.map(values, function(value)
        if value == 'true' then
            
            return true
        elseif value == 'false' then
            
            return false
        end
        
        return value
    end)
end

function _M.__:validateRequiredUnless(attr, value, params)

    self:requireParamCount(2, params, 'required_unless')
    local data = tb.get(self.data, params[1])
    local values = tb.slice(params, 1)
    if not tb.inList(values, data) then
        
        return self:validateRequired(attr, value)
    end
    
    return true
end

function _M.__:validateRequiredWith(attr, value, params)

    if not self:allFailingRequired(params) then
        
        return self:validateRequired(attr, value)
    end
    
    return true
end

function _M.__:validateRequiredWithAll(attr, value, params)

    if not self:anyFailingRequired(params) then
        
        return self:validateRequired(attr, value)
    end
    
    return true
end

function _M.__:validateRequiredWithout(attr, value, params)

    if self:anyFailingRequired(params) then
        
        return self:validateRequired(attr, value)
    end
    
    return true
end

function _M.__:validateRequiredWithoutAll(attr, value, params)

    if self:allFailingRequired(params) then
        
        return self:validateRequired(attr, value)
    end
    
    return true
end

function _M.__:anyFailingRequired(attrs)

    for _, key in pairs(attrs) do
        if not self:validateRequired(key, self:getValue(key)) then
            
            return true
        end
    end
    
    return false
end

function _M.__:allFailingRequired(attrs)

    for _, key in pairs(attrs) do
        if self:validateRequired(key, self:getValue(key)) then
            
            return false
        end
    end
    
    return true
end

function _M.__:validateSame(attr, value, params)

    self:requireParamCount(1, params, 'same')
    local other = tb.get(self.data, params[1])
    
    return value == other
end

function _M.__:validateSize(attr, value, params)

    self:requireParamCount(1, params, 'size')
    
    return self:getSize(attr, value) == params[1]
end

function _M.__:validateSometimes()

    return true
end

function _M.__:validateString(attr, value)

    return lf.isStr(value)
end

function _M.__:validateTimezone(attr, value)

    
    return lf.isDtZone(value)
end

function _M.__:validateUrl(attr, value)

    if not lf.isStr(value) then
        
        return false
    end
    
    return lf.isValidUrl(value)
end

function _M.__:getSize(attr, value)

    local hasNumeric = self:hasRule(attr, self.numericRules)

    if lf.isNum(value) and hasNumeric then
        
        return value
    elseif lf.isTbl(value) then
        
        return #value
    elseif lf.isA(value, 'file') then
        
        return value:getSize() / 1024
    end

    return str.len(value)
end

function _M:isValidFileInstance(value)

    if value:__is('uploadedFile') and not value:isValid() then
        
        return false
    end
    
    return value:__is('fileInfo')
end

function _M.__:compare(first, second, operator)

    local st = operator
    if st == '<' then
        
        return first < second
    elseif st == '>' then
        
        return first > second
    elseif st == '<=' then
        
        return first <= second
    elseif st == '>=' then
        
        return first >= second
    else 
        lx.throw('invalidArgumentException')
    end
end

function _M.__:parseNamedParams(params)

    return tb.reduce(params, function(result, item)
        local key, value = unpack(tb.pad(str.split(item, '=', 2), 2, nil))
        result[key] = value
        
        return result
    end)
end

function _M.__:requireParamCount(count, params, rule)

    if #params < count then
        lx.throw(
            'invalidArgumentException',
            fmt('Validation rule %s requires at least %s params.', rule, count)
        )
    end
end

return _M

