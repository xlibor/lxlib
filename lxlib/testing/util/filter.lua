
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

-- Filters stack frames from PHPUnit classes.
-- @param Exception e
-- @param bool      asString
-- @return string

function _M.s__.getFilteredStacktrace(e, asString)

    asString = lf.needTrue(asString)
    local eLine
    local eFile
    local eTrace
    local filteredStacktrace
    local prefix = false
    local script = realpath(GLOBALS['_SERVER']['SCRIPT_NAME'])
    if defined('__PHPUNIT_PHAR_ROOT__') then
        prefix = __PHPUNIT_PHAR_ROOT__
    end
    if asString == true then
        filteredStacktrace = ''
     else 
        filteredStacktrace = {}
    end
    if e:__is('PHPUnit_Framework_SyntheticError') then
        eTrace = e:getSyntheticTrace()
        eFile = e:getSyntheticFile()
        eLine = e:getSyntheticLine()
     elseif e:__is('PHPUnit_Framework_Exception') then
        eTrace = e:getSerializableTrace()
        eFile = e:getFile()
        eLine = e:getLine()
     else 
        if e:getPrevious() then
            e = e:getPrevious()
        end
        eTrace = e:getTrace()
        eFile = e:getFile()
        eLine = e:getLine()
    end
    if not static.frameExists(eTrace, eFile, eLine) then
        tb.unshift(eTrace, {file = eFile, line = eLine})
    end
    local blacklist = new('pHPUnit_Util_Blacklist')
    for _, frame in pairs(eTrace) do
        if frame['file'] and is_file(frame['file']) and not blacklist:isBlacklisted(frame['file']) and (prefix == false or str.strpos(frame['file'], prefix) ~= 0) and frame['file'] ~= script then
            if asString == true then
                filteredStacktrace = filteredStacktrace .. fmt("%s:%s\n", frame['file'], frame['line'] and frame['line'] or '?')
             else 
                tapd(filteredStacktrace, frame)
            end
        end
    end
    
    return filteredStacktrace
end

-- @param table  trace
-- @param string file
-- @param int    line
-- @return bool
-- @since Method available since Release 3.3.2

function _M.s__.frameExists(trace, file, line)

    for _, frame in pairs(trace) do
        if frame['file'] and frame['file'] == file and frame['line'] and frame['line'] == line then
            
            return true
        end
    end
    
    return false
end

return _M

