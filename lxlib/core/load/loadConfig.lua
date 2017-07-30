
local _M = {
    _cls_ = ''
}

local mt = { __index = _M }

local lx = require('lxlib')
local new = lx.new
local fs = lx.fs

function _M:new()
    
    local this = {}

    setmetatable(this, mt)
    
    return this
end

function _M:load(app)

    local items = lx.n.obj()

    local confs = fs.files(app.confDir, 'n', function(file)

        local name, ext = file:sub(1, -5), file:sub(-3)

        if ext == 'lua' then
            return name
        end
    end)

    app:single('config', 'lxlib.conf.config')
    local config = app:make('config', {})
    app._config = config
    
    local path

    for k, v in ipairs(confs) do
        path = app.confPath .. '.' .. v
        config:set(v, require(path))
    end
end

return _M

