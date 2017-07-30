
local lx, _M = oo{ 
    _cls_ = '',
    _ext_ = 'command'
}

local app, lf, tb, str = lx.kit()
local fs = lx.fs

function _M:ctor()

    self.resolver = app:get('db')
end

function _M:run()

    self.resolver:setDefaultConnection(self:getDatabase())

    self:getSeeder():run()
end

function _M:getSeeder(class)

    class = class or self:arg('class') or 'dbSeeder'
    class = self:getSeederPath(class)
    app:bind(class)
    
    local obj = app:make(class, self)

    return obj
end

function _M:getDatabase()

    local db = self:arg('db')
    if not db then
        db = app:conf('db.default')
    end

    return db
end

function _M:getSeederPath(class)

    return 'db.seed.'..class
end

return _M

