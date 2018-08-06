
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'lxlib.http.base.response',
    _mix_ = 'responseMix'
}

local app, lf, tb, str = lx.kit()

function _M:ctor(data, status, headers, options)

    headers = headers or {}
    status = status or 200
    self.__skip = true
    self:__super('ctor', data, status, headers)
    self:setData(data)
end


return _M

