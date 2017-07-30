
local lx, _M, mt = oo{
    _cls_    = '',
    _bond_    = 'hasherBond'
}

local app, lf, tb, str = lx.kit()

local hex = lf.hex

local sha1 = require('resty.sha1')
local sha224 = require('resty.sha224')
local sha256 = require('resty.sha256')
local sha384 = require('resty.sha384')
local sha512 = require('resty.sha512')

function _M:new()

    local this = {

    }

    return oo(this, mt)
end

function _M:ctor(config)

    local level = config.level or 1

    if level == 1 then
        self.sha = sha1
    elseif level == 224 then
        self.sha = sha224
    elseif level == 256 then
        self.sha = sha256
    elseif level == 384 then
        self.sha = sha384
    elseif level == 512 then
        self.sha = sha512
    else
        error('unsupported sha level:' .. level)
    end
end
 
function _M:make(value, options)

    local obj = self.sha:new()
    obj:update(value)

    local ret = obj:final()
    ret = hex(ret)

    return ret
end

function _M:check(value, hashedValue, options)

    if not value or not hashedValue then
        return false
    end

    if self:make(value, options) == hashedValue then
        return true
    end

    return false
end

return _M

