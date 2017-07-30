
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

-- Exports a value as a string
-- The output of this method is similar to the output of print_r(), but
-- improved in various aspects:
--  - NULL is rendered as "null" (instead of "")
--  - TRUE is rendered as "true" (instead of "1")
--  - FALSE is rendered as "false" (instead of "")
--  - Strings are always quoted with single quotes
--  - Carriage returns and newlines are normalized to \n
--  - Recursion and repeated rendering is treated properly
-- @param  mixed|null       value
-- @param  int|null         indentation The indentation level of the 2nd+ line
-- @return string

function _M:export(value, indentation)

    indentation = indentation or 0
    
    return self:recursiveExport(value, indentation)
end

-- @param  mixed   data
-- @param  Context context
-- @return string

function _M:shortenedRecursiveExport(data, context)

    local result = {}
    local exporter = new('self')
    if not context then
        context = new('context')
    end
    local array = data
    context:add(data)
    for key, value in pairs(array) do
        if lf.isTbl(value) then
            if context:contains(data[key]) ~= false then
                tapd(result, '*RECURSION*')
             else 
                tapd(result, fmt('array(%s)', self:shortenedRecursiveExport(data[key], context)))
            end
         else 
            tapd(result, exporter:shortenedExport(value))
        end
    end
    
    return str.join(result, ', ')
end

-- Exports a value into a single-line string
-- The output of this method is similar to the output of
-- SebastianBergmann\Exporter\Exporter::export().
-- Newlines are replaced by the visible string '\n'.
-- Contents of tables and objects (if any) are replaced by '...'.
-- @param  mixed|null  value
-- @return string
-- @see    SebastianBergmann\Exporter\Exporter::export

function _M:shortenedExport(value)

    local string
    if lf.isStr(value) then
        string = self:export(value)
 
        if str.len(string) > 40 then
            string = str.substr(string, 0, 30) .. '...' .. str.substr(string, -7)
        end

        return str.replace(string, "\n", '\\n')
    end
    if lf.isObj(value) then
        
        return fmt('%s Object (%s)', value.__cls, #self:toArray(value) > 0 and '...' or '')
    end
    if lf.isTbl(value) then
        
        return fmt('Array (%s)', #value > 0 and '...' or '')
    end
    
    return self:export(value)
end

-- Converts an object to an table containing all of its private, protected
-- and public properties.
-- @param  mixed value
-- @return table

function _M:toArray(value)

    local key
    if not lf.isObj(value) then
        
        return lf.needList(value)
    end
    local array = {}
    for key, val in pairs(lf.needList(value)) do
 
        array[key] = val
    end

    return array
end

-- Recursive implementation of export
-- @param  mixed|null                   value       The value to export
-- @param  int                          indentation The indentation level of the 2nd+ line
-- @param  unit.recursionContext|null   processed   Previously processed objects
-- @return string

function _M.__:recursiveExport(value, indentation, processed)

    local hash
    local class
    local values
    local key
    local array

    local ret
    local vt = type(value)

    if vt == 'table' then
        if lf.isObj(value) then
            ret = value.__cls
        else
            ret = tostring(value)
        end
    else
        ret = tostring(value)
    end

    return ret
end

return _M

