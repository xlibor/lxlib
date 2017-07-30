
local _M = {
    _cls_ = ''
}

local mt = { __index = _M }
 
function _M:new()
    local this = {

    }

    setmetatable(this, mt)
    
    return this
end

function _M:load(app)
 
    app:regConfigedBoxes()
end

return _M

