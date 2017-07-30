
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'nameParser',
    _bond_ = 'translatorBond',
}

local app, lf, tb, str = lx.kit()

function _M:ctor(loader, locale)

    self.loader = loader
    self.locale = locale
    self.fallback = nil
    self.loaded = {}
    self.selector = nil
end

function _M:hasForLocale(key, locale)

    return self:has(key, locale, false)
end

function _M:has(key, locale, fallback)

    fallback = lf.needTrue(fallback)
    
    return self:get(key, {}, locale, fallback) ~= key
end

function _M:trans(key, replace, locale)

    replace = replace or {}
    
    return self:get(key, replace, locale)
end

function _M:get(key, replace, locale, fallback)

    fallback = lf.needTrue(fallback)
    replace = replace or {}
    local line
    local namespace, group, item = unpack(self:parse(key))

    local locales = fallback
        and self:localeArray(locale)
        or {locale or self.locale}

    for _, locale in ipairs(locales) do
        line = self:getLine(namespace, group, locale, item, replace)
        if line then
            break
        end
    end

    if line then
        
        return line
    end
    
    return key
end

function _M:getFromJson(key, replace, locale)

    replace = replace or {}
    local fallback
    locale = locale or self.locale
    
    self:load('*', '*', locale)
    local line = tb.gain(self.loaded, '*', '*', locale, key)
    
    if not line then
        fallback = self:get(key, replace, locale)
        if fallback ~= key then
            
            return fallback
        end
    end
    
    return self:makeReplacements(line or key, replace)
end

function _M:transChoice(key, number, replace, locale)

    replace = replace or {}
    
    return self:choice(key, number, replace, locale)
end

function _M:choice(key, number, replace, locale)

    replace = replace or {}
    locale = self:localeForChoice(locale)
    local line = self:get(key, replace, locale)
    
    if lf.isTbl(number) then
        number = tb.count(number)
    end
    replace.count = number
    
    return self:makeReplacements(self:getSelector():choose(line, number, locale), replace)
end

function _M.__:localeForChoice(locale)

    return locale or self.locale or self.fallback
end

function _M.__:getLine(namespace, group, locale, item, replace)

    self:load(namespace, group, locale)

    local line = tb.get(
        tb.gain(self.loaded, namespace, group, locale),
        item
    )

    if lf.isStr(line) then
        
        return self:makeReplacements(line, replace)
    elseif lf.isTbl(line) and tb.count(line) > 0 then
        
        return line
    end
end

function _M.__:makeReplacements(line, replace)

    replace = self:sortReplacements(replace)
    for key, value in pairs(replace) do
        line = str.replace(
            line,
            {':' .. key, ':' .. str.upper(key), ':' .. str.ucfirst(key)},
            {value, str.upper(value), str.ucfirst(value)}
        )
    end
    
    return line
end

function _M.__:sortReplacements(replace)

    local ret = tb.sort(replace, function(value, key)
        
        return slen(key) * -1
    end)

    return ret
end

function _M:addLines(lines, locale, namespace)

    namespace = namespace or '*'
    for key, value in pairs(lines) do
        local group, item = str.div(key, '.')
        tb.set(self.loaded,
            str.join({namespace, group, locale, item}, '.'),
            value
        )
    end
end

function _M:load(namespace, group, locale)

    if self:isLoaded(namespace, group, locale) then

        return
    end

    local lines = self.loader:load(locale, group, namespace)
    tb.set(self.loaded, namespace, group, locale, lines)
end

function _M.__:isLoaded(namespace, group, locale)

    return tb.gain(self.loaded, namespace, group, locale)
end

function _M:addNamespace(namespace, hint)

    self.loader:addNamespace(namespace, hint)
end

function _M:parse(key)

    local segments = self:__super('parse', key)
    if not segments[1] then
        segments[1] = '*'
    end
    
    return segments
end

function _M.__:localeArray(locale)

    return {locale or self.locale, self.fallback}
end

function _M:getSelector()

    if not self.selector then
        self.selector = new('messageSelector')
    end
    
    return self.selector
end

function _M:setSelector(selector)

    self.selector = selector
end

function _M:getLoader()

    return self.loader
end

function _M:locale()

    return self:getLocale()
end

function _M:getLocale()

    return self.locale
end

function _M:setLocale(locale)

    self.locale = locale
end

function _M:getFallback()

    return self.fallback
end

function _M:setFallback(fallback)

    self.fallback = fallback
end

return _M

