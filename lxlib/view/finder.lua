
local lx, _M, mt = oo{
    _cls_    = ''    
}

local app, lf, tb, str = lx.kit()

function _M:new(fs, paths, extension)

    local this = {
        fs = fs,
        paths = paths,
        namespaces = {},
        views = {},
        extension = extension
    }

    oo(this, mt)

    return this
end

function _M:find(view, namespace)

    local path = self.views[view]
    if path then
        return path
    end

    if namespace then
        return self:findInNamespace(view, namespace)
    end

    path = self:findInPaths(view)
    if path then
        self.views[view] = path
    end

    return path
end

function _M:findInPaths(view)

    local fs = self.fs
    local paths = self.paths
    local extension = self.extension
    local t

    view = str.gsub(view, '%.', '/')
    
    for _, path in ipairs(paths) do 
        t = path .. '/' .. view .. '.' .. extension

        if fs.exists(t) then
            return t
        end
    end

    lx.throw('invalidArgumentException',
        'view ' .. view .. ' not found. extension:' .. extension)

end

function _M:findInNamespace(view, namespace)

    local currNs = self.namespaces[namespace]
    local path = currNs.path

    local fs = self.fs
    local extension = self.extension
    local t

    t = path .. '/' .. view .. '.' .. extension
    if fs.exists(t) then
        return t
    end
 
    lx.throw('invalidArgumentException',
        'view ' .. t .. ' not found.')

end

function _M:addNamespace(namespace, path, engine)

    self.namespaces[namespace] = {path = path, engine = engine}
end

function _M:getEngineFromNamespace(namespace)

    local ns = self.namespaces[namespace]
    if ns then
        return ns.engine
    else
        namespace = namespace or 'unkonwn'
        error('no namespace:'..namespace)
    end
end

function _M:getInfoFromPath(path)

    local engine, namespace

    local i, j = str.find(path, '%s')

    if i then
        return path
    end

    if str.find(path, '@') then
        engine, path = str.div(path, '@')
    end

    if str.find(path, ':') then
        namespace, path = str.div(path, ':')
    end

    return path, engine, namespace
end

return _M

