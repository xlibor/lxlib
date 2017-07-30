
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()
local Query = lx.use('orm.query')

function _M:new()

    local this = {
    }
    
    oo(this, mt)

    return this
end

function _M:ctor()

    self.resolver = require('lxlib.resty.messagePack')
    -- self.resolver = require('cmsgpack')
end

function _M:pack(data)

    if lf.isTbl(data) then
        data = self:traverseForPack(data)
    end

    return self.resolver.pack(data)
end

function _M:traverseForPack(tbl)

    local ret = {}
    local newNode

    if tbl.__cls and tbl:__is('packable') then
        tbl = self:getPackable(tbl)
    end

    for k, v in pairs(tbl) do
        if lf.isTbl(v) then
            if v.__cls and v:__is('packable') then
                v = self:getPackable(v)
                newNode = {}
                for kk, vv in pairs(v) do
                    if lf.isTbl(vv) then
                        vv = self:traverseForPack(vv)
                    end
                    newNode[kk] = vv
                end
                v = newNode
            elseif #v > 0 then
                v = self:traverseForPack(v)
            end
        end

        ret[k] = v
    end

    return ret
end

function _M:getPackable(obj)

    local nick = obj.__nick or obj.__cls
    local args

    obj, args = obj:pack(self)
    rawset(obj, '__packFrom', {nick, args})

    return obj
end

function _M:unpack(str)

    local value = self.resolver.unpack(str)

    if lf.isTbl(value) then
        value = self:traverseForUnpack(value)
    end

    return value
end

function _M:traverseForUnpack(tbl)

    for k, v in pairs(tbl) do
        if lf.isTbl(v) then
            if next(v) then
                v = self:traverseForUnpack(v)
            elseif #v > 0 then
                v = self:traverseForUnpack(v)
            end
            tbl[k] = v
        end
    end

    if rawget(tbl, '__packFrom') then
        tbl = self:getPackFrom(tbl)
    end

    if #tbl > 0 then
        if lf.isA(tbl[1], 'model') then
            Query.setModelsMt(tbl)
        end
    end

    return tbl
end

function _M:getPackFrom(value)

    local packFrom = value.__packFrom
    local nick, args = packFrom[1], packFrom[2]
    value.__packFrom = nil

    local obj
    if args then
        obj = app:make(nick, unpack(args))
    else
        obj = app:make(nick)
    end
    obj:unpack(value, self)

    return obj
end

function _M:use(resolver)

    self.resolver = resolver
end

return _M

