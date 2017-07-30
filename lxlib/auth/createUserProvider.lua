
local lx, _M = oo{
    _cls_ = ''
}

local app, lf, tb, str, new = lx.kit()
local throw = lx.throw

function _M:ctor()

    self.customProviderCreators = {}
end

function _M:createUserProvider(provider)

    local config = app('config')['auth.providers.' .. provider]
    if self.customProviderCreators[config['driver']] then
        
        return lf.call(self.customProviderCreators[config['driver']], config)
    end

    local st = config['driver']
    if st == 'db' then
        
        return self:createDbProvider(config)
    elseif st == 'orm' then
        
        return self:createOrmProvider(config)
    else
        throw('invalidArgumentException',
            'Authentication user provider [' .. st .. '] is not defined.'
        )
    end
end

function _M:createDbProvider(config)

    local conn = app.db:connection()
    
    return new('auth.dbUserProvider', conn, app('hash'), config.table)
end

function _M:createOrmProvider(config)

    return new('auth.ormUserProvider', app('hash'), config.model)
end

return _M

