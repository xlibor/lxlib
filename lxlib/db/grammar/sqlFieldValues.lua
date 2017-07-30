
local _M = {
    _cls_ = '@sqlFieldValues'
}
local mt = { __index = _M }

local lx = require('lxlib')
local dbInit = lx.db

function _M:new()

    local this = {
        items = {}
    }
    
    setmetatable(this, mt)

    return this
end
    
function _M:add(fieldName, value)

    local field = dbInit.sqlFieldValue(fieldName, value)
 
    local items = self.items
    items[fieldName] = field
 
    return field
end
 
return _M