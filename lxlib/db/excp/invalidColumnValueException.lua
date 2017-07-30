
local _M = { 
    _cls_     = '',
    _ext_     = 'runtimeException'
}

local mt = { __index = _M }

function _M:ctor(field, compareOperator)

    local vt = type(field)
    local column
    if vt == 'string' then
        column = field
    else
        column = 'unkonwn'
    end

    compareOperator = compareOperator or 'unkonwn'
    self.msg = 'column: "' .. column .. '", compareOperator: "'
        .. compareOperator .. '"'
end

return _M

