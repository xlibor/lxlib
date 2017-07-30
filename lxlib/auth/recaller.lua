
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

function _M:new(recaller)

    local this = {
        recaller = recaller
    }

    oo(this, mt)

    return this
end

function _M.d__:id()

    return str.split(self.recaller, '|', 2)[1]
end

function _M.d__:token()

    return str.split(self.recaller, '|', 2)[2]
end

function _M.c__:valid()

    return self:properString() and self:hasBothSegments()
end

function _M.c__:properString()

    return lf.isStr(self.recaller) and str.contains(self.recaller, '|')
end

function _M.c__:hasBothSegments()

    local segments = str.split(self.recaller, '|')
    
    return #segments == 2 and str.trim(segments[1]) ~= '' and str.trim(segments[2]) ~= ''
end

return _M

