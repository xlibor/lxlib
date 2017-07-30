
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'logBaseHandler'
}

local app, lf, tb, str = lx.kit()

local Logger = lx.use('logger')

-- @param int level The minimum logging level at which this handler will be triggered

function _M:ctor(level)

    level = level or Logger.debug
    self.__skip = true
    self:__super('ctor', level, false)
end

-- {@inheritdoc}

function _M:handle(record)

    dd(self, record)
    if record['level'] < self.level then
        
        return false
    end
    
    return true
end

function _M:write()

end

return _M

