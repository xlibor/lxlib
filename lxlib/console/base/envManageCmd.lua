
local _M = { 
    _cls_ = '',
    _ext_ = 'command',
    sign = {
        showAll = {
            indent = {short = 'i', opt = true, value = true}
        },
        get = {
            key = {index = 1}
        }
    }
}

local mt = { __index = _M }

local lx = require('lxlib').load(_M)
local app = lx.app()
local fs = lx.fs
 
function _M:ctor()

end

function _M:showAll()

    local indent = self:arg('indent')
    local col = lx.env
    self:text(col:toJson(_, indent))
end

function _M:get()

    local key = self:arg('key')
    if key then
        local col = lx.env

        self:text(col:get(key))
    else
        self:warn('not input key')
    end
end

return _M

