
local _M = { 
    _cls_ = '',
    _ext_ = 'command'
}

local mt = { __index = _M }

local lx = require('lxlib')
local app = lx.app()

function _M:run()
    
    local args = self.args
    self:info(self.rootPath)
    local view = app:make('view')
    local tpl = 'some plain str, aa:{{aa}}, bb:{{bb}}'
    local ctx = {aa = 11, bb = 22}
    self:info(view(tpl, ctx))
    self:line('line')
    self:comment('comment')
    self:warn('warn')
    self:write({text = 'hello ', style ='info'}, {text = 'world', style = 'warn'})
    -- self:line('<error>attention</error><comment>please</comment>')
    self:error('error')
    self:call('env/get', {key = 'db'})

    self:print('abc')
    self:print('efg')
    self:line('over')
end

return _M

