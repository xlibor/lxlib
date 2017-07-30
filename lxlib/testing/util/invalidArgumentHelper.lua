
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str, new = lx.kit()

-- @param int               argument
-- @param string            type
-- @param mixed|null        value

function _M.factory(argument, vt, value)

    local stack = lx.trace(2)

    lx.throw('unit.exception',
        fmt('Argument #%d%sof %s:%s() must be a %s',
            argument,
            ' (' .. tostring(value) .. ') ',
            stack.file,
            stack.func,
            vt
        )
    )
end

return _M

