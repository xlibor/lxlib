
local lx, _M, mt = oo{
    _cls_ = '',
    _bond_ = 'translationLoaderBond'
}

local app, lf, tb, str = lx.kit()

function _M:new(files, path)

    local this = {
        files = files,
        path = path,
        hints = {}
    }
    
    return oo(this, mt)
end

function _M:load(locale, group, namespace)

    if group == '*' and namespace == '*' then
        
        return self:loadJsonPath(self.path, locale)
    end
    if not namespace or namespace == '*' then
        
        return self:loadPath(self.path, locale, group)
    end
    
    return self:loadNamespaced(locale, group, namespace)
end

function _M.__:loadNamespaced(locale, group, namespace)

    local lines
    if self.hints[namespace] then
        lines = self:loadPath(self.hints[namespace], locale, group)
        
        return self:loadNamespaceOverrides(lines, locale, group, namespace)
    end
    
    return {}
end

function _M.__:loadNamespaceOverrides(lines, locale, group, namespace)

    local file = "{self.path}/vendor/{namespace}/{locale}/{group}.php"
    if self.files:exists(file) then
        
        return array_replace_recursive(lines, self.files:getRequire(file))
    end
    
    return lines
end

function _M.__:loadPath(path, locale, group)

    local full = fmt('%s.%s.%s', path, locale, group)

    local info, err = lf.prequire(full)
    if not info then
        error(err)
    end
    
    return info or {}
end

function _M.__:loadJsonPath(path, locale)

    local full = "{path}/{locale}.json"
    if self.files:exists(full) then
        
        return json_decode(self.files:get(full), true)
    end
    
    return {}
end

function _M:addNamespace(namespace, hint)

    self.hints[namespace] = hint
end

function _M:namespaces()

    return self.hints
end

return _M

