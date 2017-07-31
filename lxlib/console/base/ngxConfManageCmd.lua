
local _M = { 
    _cls_ = '',
    _ext_ = 'command'
}

local mt = { __index = _M }

local lx = require('lxlib')
local app, lf, tb, str = lx.kit()
local fs = lx.fs

function _M:ctor()

end

function _M:update()
    
    local args = self.args

    local view = app:make('view')
    local rootPath = self.rootPath
    local libPath = self.libPath
    local pubPath = self.pubPath
    local appNames = tb.keys(self:envGet('apps'))
    local tplOriginalPath = libPath .. '/support/ngx.conf'
    local mimeTypeOriginalPath = libPath .. '/support/mime.types'
    local tplPath = pubPath .. '/ngxTpl.conf'
    local mimeTypePath = pubPath .. '/mime.types'
    local ngxPath = ngx.config.prefix() or '/usr/local/openresty/nginx/'
    local appLogPath = pubPath .. '/log'
    local appPath = app.basePath
    local codeCache = self:envGet('codeCache') and 'on' or 'off'
    
    if not fs.exists(tplPath) then
        fs.copy(tplOriginalPath, tplPath)
        fs.copy(mimeTypeOriginalPath, mimeTypePath)
    end

    local tpl = fs.get(tplPath)

    local ctx = {
        port = 80,
        serverName = 'localhost',
        appNames = appNames,
        luaCodeCache = codeCache,
        ngxPath = ngxPath,
        lxpubPath = pubPath,
        assetPath = rootPath,
        appLogPath = appLogPath,
        appPath = appPath,
        initWorkerByLua = [[require("lxlib").init()]],
        luaPackagePath = fmt('%s/?.lua;%s/?/init.lua;;', rootPath, rootPath),
        contentByLua = [[require("lxlib").serve()]],
    }

    local confStr = view:get(tpl, ctx)
    local confPath = pubPath .. '/nginx.conf'
    fs.put(confPath, confStr)

    self:info('nginx.conf compiled in '..confPath)
end

function _M:clear()

    local pubPath = self.pubPath
    local tplPath = pubPath..'/ngxTpl.conf'
    local confPath = pubPath..'/nginx.conf'

    fs.delete{tplPath, confPath}

    self:info('nginx.conf and ngxTpl.conf deleted')
end

return _M

