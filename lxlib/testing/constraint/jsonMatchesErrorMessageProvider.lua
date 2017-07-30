-- This file is part of PHPUnit.
-- (c) Sebastian Bergmann <sebastian@phpunit.de>
-- For the full copyright and license information, please view the LICENSE
-- file that was distributed with this source code.
-- Provides human readable messages for each JSON error.


local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

-- Translates JSON error to a human readable string.
-- @param string error
-- @param string prefix
-- @return string

function _M.s__.determineJsonError(error, prefix)

    prefix = prefix or ''
    local st = error
    if st == JSON_ERROR_NONE then
        
        return
     elseif st == JSON_ERROR_DEPTH then
        
        return prefix .. 'Maximum stack depth exceeded'
     elseif st == JSON_ERROR_STATE_MISMATCH then
        
        return prefix .. 'Underflow or the modes mismatch'
     elseif st == JSON_ERROR_CTRL_CHAR then
        
        return prefix .. 'Unexpected control character found'
     elseif st == JSON_ERROR_SYNTAX then
        
        return prefix .. 'Syntax error, malformed JSON'
     elseif st == JSON_ERROR_UTF8 then
        
        return prefix .. 'Malformed UTF-8 characters, possibly incorrectly encoded'
     else 
        
        return prefix .. 'Unknown error'
    end
end

-- Translates a given type to a human readable message prefix.
-- @param string type
-- @return string

function _M.s__.translateTypeToPrefix(type)

    local st = \str.lower(type)
    if st == 'expected' then
        prefix = 'Expected value JSON decode error - '
     elseif st == 'actual' then
        prefix = 'Actual value JSON decode error - '
     else 
        prefix = ''
    end
    
    return prefix
end

return _M

