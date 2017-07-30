
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str, new = lx.kit()
local fs = lx.fs

function _M:new()

    local this = {
        definitions = {}
    }
    
    return oo(this, mt)
end

function _M:ctor(faker)

    self.faker = faker
end

function _M:construct(faker, pathToFair)

    pathToFair = pathToFair or lx.dir('db','seed/fair')
    
    return self:__new(faker):load(pathToFair)
end

function _M:defineAs(class, name, attributes)

    return self:define(class, attributes, name)
end

function _M:define(class, attributes, name)

    class = lf.needCls(class)

    name = name or 'default'
    tb.set(self.definitions, class, name, attributes)
end

function _M:create(class, attributes)

    class = lf.needCls(class)
    attributes = attributes or {}
    
    return self:of(class):create(attributes)
end

function _M:createAs(class, name, attributes)

    attributes = attributes or {}
    
    return self:of(class, name):create(attributes)
end

function _M:load(path)

    local fair = self

    if fs.isDir(path) then
        local files = fs.files(path, 'n', function(file)
            local name, ext = file:sub(1, -5), file:sub(-3)

            if ext == 'lua' then
                return name
            end
        end)
        for _, file in ipairs(files) do
            file = app.dbPath..'.seed.fair.' .. file
            require(file)(self)
        end
    end
    
    return fair
end

function _M:make(class, attributes)

    attributes = attributes or {}
    
    return self:of(class):make(attributes)
end

function _M:makeAs(class, name, attributes)

    attributes = attributes or {}
    
    return self:of(class, name):make(attributes)
end

function _M:rawOf(class, name, attributes)

    attributes = attributes or {}
    
    return self:raw(class, attributes, name)
end

function _M:raw(class, attributes, name)

    class = lf.needCls(class)
    name = name or 'default'
    attributes = attributes or {}
    local raw = lf.call(self.definitions[class][name], self.faker)
    
    return tb.merge(raw, attributes)
end

function _M:of(class, name)

    class = lf.needCls(class)
    name = name or 'default'
    
    return new('db.seed.fairBuilder', class, name, self.definitions, self.faker)
end

return _M

