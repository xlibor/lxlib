
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'exception'
}

local app, lf, tb, str = lx.kit()

function _M:ctor(validator, response)

    self.msg = 'The given data failed to pass validation.'
    self.validator = validator
    self.response = response
end

function _M:getResponse()

    return self.response
end

return _M

