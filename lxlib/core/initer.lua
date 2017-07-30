
local _M = {
    _cls_ = ''
}

local mt = { __index = _M }

local colBase = require('lxlib.base.col')
local lf = require('lxlib.base.pub')
local tmaxn = table.maxn

function _M.col(...)

    local args = {...}
    local p1, p1Type

    if #args > 0 then
        p1 = args[1]
        p1Type = type(p1)
        
        if p1Type == 'table' then
            if lf.isList(p1, true) then
                return _M.arr(...)
            elseif next(p1) then
                return _M.obj(...)
            else 
                return colBase:new()
            end
        else
            return _M.obj(...)
        end
    else
        return colBase:new()
    end
end

function _M.obj(...)

    local col = colBase:new()
    col:useDict()
    col:init(...)

    return col
end

function _M.arr(...)

    local col = colBase:new()
    col:useList()
    col:init(...)
     
    return col
end

function _M.app(scaffold)

    local lx = require('lxlib')
 
    local container = require('lxlib.core.container'):new()
 
    container:single('app', 'lxlib.core.application')

    local appPath = ngx.ctx.lxAppPath
    local appName = ngx.ctx.lxAppName

    lx.addApp(container, appName)

    local app = container:makeWith('app', container, appPath, appName, scaffold)
 
    return app
end

return _M

