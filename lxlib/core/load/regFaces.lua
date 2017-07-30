
local _M = {
    _cls_ = ''
}

local mt = { __index = _M }

local lx = require('lxlib')

function _M:new()

    local this = {

    }

    setmetatable(this, mt)
    
    return this
end

function _M:load(app)

    local faces = app:conf('app.faces')

    local vt
    if faces then
        for k, v in pairs(faces) do
            app:face(k, v)
        end
    end
end

return _M

