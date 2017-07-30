
local _M = {
    _cls_    = ''
}

local mt = { __index = function(this, key)

    return key

end}

function _M:new(baseDbos)

    if baseDbos then 

        return baseDbos
    else
        local this = {
        }
        setmetatable(this, mt)

        return this
    end
end

return _M

