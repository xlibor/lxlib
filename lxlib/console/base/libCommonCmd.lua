
local _M = { 
    _cls_ = '',
    _ext_ = 'command'
}

local mt = { __index = _M }

local lx = require('lxlib')
local app = lx.app()
 
function _M:ctor()

end

function _M:about()

    self:info('this is lxlib console tool.')
end

function _M:version()

    self:info('lxlib version:' .. lx.version)

end

function _M:help()
    
    self:info(
[[
    help: show help
    list: list all commands
]])

end

return _M

