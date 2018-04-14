
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()
local sfind, ssub, slen = string.find, string.sub, string.len

function _M:new(...)

    local this = {
        y = 0, m = 0, d = 0, h = 0, i = 0, s = 0,
        invert = 0
    }

    return oo(this, mt)
end

function _M:ctor(...)

    local args, len = lf.getArgs(...)
    local p1 = args[1]
    local vt = type(p1)

    if len == 1 and vt == 'string' then
        self:initWithString(p1)
    elseif vt == 'number' then
        self:initWithArgs(unpack(args))
    elseif vt == 'table' then
        self:initWithDto(p1)
    end

end

function _M:initWithDto(dto)

    -- local y, m, d, h, i, s = 0, 0, 0, 0, 0, 0
    
end

function _M:initWithString(s)

    local sign = ssub(s, 1, 1)
    if not sign == 'P' then
        error('invalid interval format')
    end

    s = ssub(s, 2)

    local dict = {}
    local k, v
    local stime 
    local i = sfind(s, 'T')
    if i then
        stime = ssub(s, i + 1)
        s = ssub(s, 1, i - 1)
    end

    for i = 1, slen(s), 2 do
        k = ssub(s, i+1, i+1)
        v = tonumber(ssub(s, i, i))
        dict[k] = v
    end

    local Y, M, D = dict.Y, dict.M, dict.D
    if Y then self.y = Y end
    if M then self.m = M end
    if D then self.d = D end

    if stime then
        dict = {}
        s = stime
        for i = 1, slen(s), 2 do
            k = ssub(s, i+1, i+1)
            v = tonumber(ssub(s, i, i))
            dict[k] = v
        end
        local H, M, S = dict.H, dict.M, dict.S
        if H then self.h = H end
        if M then self.i = M end
        if S then self.s = S end
    end

end

function _M:initWithArgs(p1, p2, p3, p4, p5, p6)

    self.y = p1
    self.m = p2 or 0
    self.d = p3 or 0
    self.h = p4 or 0
    self.i = p5 or 0
    self.s = p6 or 0
end

return _M

