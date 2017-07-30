
local lx, _M, mt = oo{
    _cls_    = '',
    _bond_    = 'hasherBond'
}

local app, lf, tb, str = lx.kit()

local hex = lf.hex

function _M:new()

    local this = {

    }

    return oo(this, mt)
end

function _M:ctor(config)

end

function _M:make(value, options)

    local ret = ngx.md5(value)

    return ret
end

function _M:check()

end

return _M

