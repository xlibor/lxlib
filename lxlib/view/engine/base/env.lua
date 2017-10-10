
local _M = {
    _cls_ = ''
}

local mt = {__index = _M}
local lx = require('lxlib')
local app, lf, tb, str = lx.kit()
local H = lx.h

local factory, common, tplFunc

function _M._init_()
    
    factory = app.view
    tplFunc = app:make('view.engine.base.func')
    local tplFilter  = app:make('view.engine.base.filter')

    common = {
        lx          = lx,
        lf          = lf,
        tb          = tb,
        tapd        = tapd,
        e           = tplFunc.escape,
        _tplMf      = tplFilter,
        _tplFunc    = tplFunc,
        __line      = function() end,
        count       = tb.count,
        empty       = lf.isEmpty,
        Str         = lx.str,
        Tb          = lx.tb,
        Lf          = lx.f,
        App         = lx.app()
    }

end

function _M:new(tpl, context, blocks)

    local this = tb.clone(common)
    app:ctx():set('viewEnv', this)

    local tplTexts = {}
    this.___ = tplTexts
    this.echo = function(p)
        tapd(tplTexts, tplFunc.toStr(p))
    end

    this.mergeContext  = function(this, data)
        for k, v in pairs(data) do
            context[k] = v
        end
    end
    
    local tpls = tpl.tpls
    local nestedData = {}
    local viewName, data
    local isPlain = (tpl.curFile == 'plain')

    if not isPlain then
        factory:runGather(context, '*', tpl)
        for _, v in ipairs(tpls) do
            viewName = v.view

            data = factory:runGather(context, viewName, tpl)
            if data then
                nestedData[viewName] = data
            end
        end

        factory:runTouch(context, '*', tpl)
    end
    
    local setCurrentView = function(viewName)

        this.currentView = viewName
        if viewName then
            data = factory:runTouch(context, viewName, tpl)
            if data then
                nestedData[viewName] = data
            end
        end
    end

    this.setCurrentView = setCurrentView
    this.Ctx = context
    
    local currView, data
    setmetatable(this, {__index = function(tbl, k)
        local t = context[k]
        if t == nil then
            t = H[k] or _G[k]
        end

        if t == nil then
            currView = rawget(this, 'currentView')
            if currView then
                data = nestedData[currView]
                if data then
                    t = data[k]
                end
            end
        end

        return t
    end})

    return this
end

return _M

