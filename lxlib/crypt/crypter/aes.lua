
local lx, _M, mt = oo{
    _cls_   = '',
    _bond_  = 'crypterBond'
}

local app, lf, tb, str = lx.kit()
local aesBase = require('resty.aes')
local aes0Base = require('lxlib.resty.aes0')

local toHex, fromHex = lf.hex, lf.fromHex
local sfind = string.find

function _M:new()

    local this = {
    }
    
    return oo(this, mt)
end

function _M:ctor(key, config)

    self.key = key
    local salt = config.salt
    self.salt = salt

    local cipher, cipherSize = config.cipher[1], config.cipher[2]
    self.cipher = cipher
    self.cipherSize = cipherSize
    local hashConf = config.hash or {}
    if #hashConf > 0 then
        local hash, hashRounds = hashConf[1], hashConf[2]
        self.hash = hash
        self.hashRounds = hashRounds
    elseif next(hashConf) then
        local iv = hashConf.iv
        self.iv = iv
    else
        error('invalid hash')
    end
    local padding = 1
    if config.padding then
        if config.padding == 0 then
            padding = 0
        end
    end
    self.padding = padding
end

function _M:getDoer(config)

    local aesCls = aesBase
    if self.padding == 0 then
        aesCls = aes0Base
    end

    local info = config or self

    local key, salt, hash, cipherSize, cipher, hashRounds, iv = 
        info.key, info.salt, info.hash, info.cipherSize,
        info.cipher, info.hashRounds, info.iv

    if hash then
        hash = aesCls.hash[hash]
    else
        hash = {iv = iv}
    end

    local aes, err = aesCls:new(
        key, salt, aesCls.cipher(cipherSize, cipher),
        hash, hashRounds
    )

    if not aes then
        error(err)
    end

    return aes
end

function _M:encrypt(value)

    self:preEnc()

    local aes = self:getDoer()
    value = aes:encrypt(value)

    value = toHex(value)

    if self.salt then
        value = value .. '^' .. self.salt
    end

    if self.iv then
        value = self.iv .. '~' .. value
    end

    return value
end

function _M.__:preEnc()

    local salt = self.salt
    if lf.isFunc(salt) then
        self.salt = salt()
    end

    local iv = self.iv
    if lf.isFunc(iv) then
        self.iv = iv()
    end

end

function _M:decrypt(payload)

    payload = self:parsePayload(payload)
    local aes = self:getDoer()

    payload = fromHex(payload)
    payload = aes:decrypt(payload)

    return payload
end

function _M.__:parsePayload(payload)

    local salt, iv
    if sfind(payload, '~') then
        iv, payload = str.div(payload, '~')
        self.iv = iv
    else
        if sfind(payload, '^', nil, true) then
            payload, salt = str.div(payload, '^')
            self.salt = salt
        end
    end

    return payload
end

return _M

