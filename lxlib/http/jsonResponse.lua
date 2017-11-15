
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

function _M:getData()

    return lf.jsde(self.data)
end

function _M:setData(data)

    data = data or {}

    if lf.isTbl(data) then
        if lf.isObj(data) then
            if data:__is('arrable') then
                self.data = lf.jsen(data:toArr())
            elseif data:__is('jsonable') then
                self.data = data:toJson()
            end
        else
            self.data = lf.jsen(data)
        end
    else
        throw('invalidArgumentException', 'data should be jsonable or table')
    end

    return self:update()
end

function _M:update()

    self:setContent(self.data)
    self:header('Content-Type', 'application/json')
end

return _M

