
local _M = { 
    _cls_ = '',
    _ext_ = 'col',

}

local mt = { __index = _M }

function _M:ctor(headers)

    self:init(headers)
    self:itemable()
    -- self:setDefault('')
end

return _M

