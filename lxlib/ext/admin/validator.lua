
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = '\Illuminate\Validation\Validator'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        overrideCustomMessages = {
        string = 'The :attribute option must be a string',
        directory = 'The :attribute option must be a valid directory',
        array = 'The :attribute option must be an array',
        array_with = 'The :attribute array is missing some required values',
        not_empty = 'The :attribute option must not be empty',
        callable = 'The :attribute option must be a function',
        eloquent = 'The :attribute option must be the string name of a valid Eloquent model'
    },
        url = nil
    }
    
    return oo(this, mt)
end

-- The URL instance.
-- @var \Illuminate\Routing\UrlGenerator
-- Injects the URL class instance.
-- @param \Illuminate\Routing\UrlGenerator url

function _M:setUrlInstance(url)

    self.url = url
end

-- Gets the URL class instance.
-- @return \Illuminate\Routing\UrlGenerator

function _M:getUrlInstance()

    return self.url
end

-- Overrides the rules and data.
-- @param table data
-- @param table rules

function _M:override(data, rules)

    self:setData(data)
    self:setRules(rules)
    self:setCustomMessages(self.overrideCustomMessages)
end

-- Sets the rules.
-- @param table rules

function _M:setRules(rules)

    self.rules = self:explodeRules(rules)
end

-- Mimic of the Laravel table_get helper.
-- @param table  table
-- @param string key
-- @param mixed  default
-- @return mixed

function _M:arrayGet(array, key, default)

    if not key then
        
        return array
    end
    if array[key] then
        
        return array[key]
    end
    for _, segment in pairs(str.split(key, '.')) do
        if not lf.isTbl(array) or not tb.has(array, segment) then
            
            return lf.value(default)
        end
        array = array[segment]
    end
    
    return array
end

-- Checks if a table is already joined to a query object.
-- @param Query  query
-- @param string table
-- @return bool

function _M:isJoined(query, table)

    local tableFound = false
    query = is_a(query, 'Illuminate\\Database\\Query\\Builder') and query or query:getQuery()
    if query.joins then
        --iterate over the joins to see if the table is there
        for _, join in pairs(query.joins) do
            if join.table == table then
                
                return true
            end
        end
    end
    
    return false
end

-- Validates that an item is a directory.

function _M:validateDirectory(attribute, value, parameters)

    return is_dir(value)
end

-- Validates that an item is an table.

function _M:validateArray(attribute, value)

    return lf.isTbl(value)
end

-- Validates that an item is an table.

function _M:validateArrayWithAllOrNone(attribute, value, parameters)

    local missing = 0
    for _, key in pairs(parameters) do
        if not value[key] then
            missing = missing + 1
        end
    end
    
    return missing == #parameters or missing == 0
end

-- Validates that an item is not empty.

function _M:validateNotEmpty(attribute, value, parameters)

    return not lf.isEmpty(value)
end

-- Validates that an item is func.

function _M:validateCallable(attribute, value, parameters)

    return lf.isCallable(value)
end

-- Validate that an attribute is a string.

function _M.__:validateString(attribute, value)

    return lf.isStr(value)
end

-- Validates that an item is either a string or func.

function _M:validateStringOrCallable(attribute, value, parameters)

    return lf.isStr(value) or lf.isCallable(value)
end

-- Validates that an item is an Eloquent model.

function _M:validateEloquent(attribute, value, parameters)

    return app:hasClass(value) and is_a(new('value'), 'Illuminate\\Database\\Eloquent\\Model')
end

return _M

