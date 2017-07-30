
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'unit.constraint'
}

local app, lf, tb, str = lx.kit()
local supportedTypes = {
    table         = true,
    array         = true,
    boolean       = true,
    bool          = true,
    double        = true,
    float         = true,
    integer       = true,
    int           = true,
    null          = true,
    numeric       = true,
    object        = true,
    string        = true,
    scalar        = true,
    callable      = true,
    ['function']  = true,
    func          = true,
}

-- @param string type

function _M:ctor(type)

    self.__skip = true
    self:__super(_M, 'ctor')
    if not supportedTypes[type] then
       lx.throw('unit.exception', fmt('Type specified for unit.constraint.isType <%s> ' .. 'is not a valid type.', type))
    end
    self.type = type
end

-- Evaluates the constraint for parameter other. Returns true if the
-- constraint is met, false otherwise.
-- @param mixed other Value or object to evaluate.
-- @return bool

function _M.__:matches(other)

    local st = self.type
    if st == 'numeric' or st == 'integer' or st == 'int' then
        return lf.isNum(other)
    elseif st == 'double' or st == 'float' or st == 'real' then
        return lf.isFloat(other)
    elseif st == 'string' then
        return lf.isStr(other)
    elseif st == 'boolean' or st == 'bool' then
        return lf.isBool(other)
    elseif st == 'null' then
        return not other
    elseif st == 'array' or st == 'table' then
        return lf.isTbl(other)
    elseif st == 'object' or st == 'obj' then
        return lf.isObj(other)
    elseif st == 'scalar' then  
        return lf.isScalar(other)
    elseif st == 'function' or st == 'func' then
        return lf.isFunc(other)
    elseif st == 'callable' then
        return lf.isCallable(other)
    else
        return false
    end
end

-- Returns a string representation of the constraint.
-- @return string

function _M:toStr()

    return fmt('is of type "%s"', self.type)
end

return _M

