
local lx, _M, mt = oo{
    _cls_           = '',
    a__             = {},
    publishes       = {},
    publishGroups   = {}
}

local app, lf, tb, str = lx.kit()
local fs = lx.fs

function _M:new()

    local this = {
    }
    
    oo(this, mt)

    return this
end

function _M.a__:reg() end

function _M.a__:boot() end

function _M:dependOn()
end

function _M:wrap()
end

function _M:mergeConfigFrom(path, key)

    local config = app:conf(key) or {}
    local data = require(path)
    config = tb.merge(config, data)

    app:setConf(key, config)
end

function _M:loadViewsFrom(path, namespace)

    local view = app.view
    local appPath = lx.dir('res', 'view/vendor/' .. namespace)
    if fs.exists(appPath) then
        view:addNamespace(namespace, path)
    end
 
    view:addNamespace(namespace, path)
end

function _M:loadTranslationsFrom(path, namespace)

    app:get('translator'):addNamespace(namespace, path)
end

function _M:loadShiftFrom(paths)

end

function _M:command(groupPath, cmds)

    app:resolving('commander', function(cmder)
        cmder:group(groupPath, function()
            for cmd, path in pairs(cmds) do
                cmder:add(cmd, path)
            end
        end)
    end)
end

function _M:publish(paths, group)

    local class = self.__cls

    if not _M.publishes[class] then
        _M.publishes[class] = {}
    end

    _M.publishes[class] = tb.merge(_M.publishes[class], paths)

    if group then
        if not _M.publishGroups[group] then
            _M.publishGroups[group] = {}
        end

        _M.publishGroups[group] = tb.merge(_M.publishGroups[group], paths)
    end
end

function _M.pathsToPublish(box, group)

    if box and group then
        if lf.isEmpty(_M.publishes[box]) or lf.isEmpty(_M.publishGroups[group]) then
            return {}
        end

        return tb.cross(_M.publishes[box], _M.publishGroups[group])
    end

    if group and _M.publishGroups[group] then
        return _M.publishGroups[group]
    end

    if box and _M.publishes[box] then
        return _M.publishes[box]
    end

    if group or box then
        return {}
    end

    local paths = {}

    for class, publish in pairs(_M.publishes) do
        paths = tb.merge(paths, publish)
    end

    return paths
end

return _M

