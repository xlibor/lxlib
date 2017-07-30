
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'unit.constraint'
}

local app, lf, tb, str = lx.kit()

-- Evaluates the constraint for parameter other. Returns true if the
-- constraint is met, false otherwise.
-- @param mixed other Value or object to evaluate.
-- @return bool

function _M.__:matches(other)

    if other == '' then
        
        return false
    end
    local tbl = lx.json.safeDecode(other)
    if not tbl then
        
        return false
    end
    
    return true
end

-- Returns the description of the failure
-- The beginning of failure messages is "Failed asserting that" in most
-- cases. This method should return the second part of that sentence.
-- @param mixed other Evaluated value or object.
-- @return string

function _M.__:failureDescription(other)

    if other == '' then
        
        return 'an empty string is valid JSON'
    end
    local tbl, pos, err = lx.json.safeDecode(other)
    
    return fmt('%s is valid JSON (%s)', self.exporter:shortenedExport(other), err)
end

-- Returns a string representation of the constraint.
-- @return string

function _M:toStr()

    return 'is valid JSON'
end

return _M

