
local lx, _M, mt = oo{
    _cls_       = '',
    _static_    = {
        globalModels    = {},
        globalTables    = {},
        loadedConfigs   = {},
        initedConfigs   = {},
    }
}

local app, lf, tb, str, new = lx.kit()

local static

function _M._init_(this)

    static = this.static
end

function _M:new()

    local this = {
        models      = {},
        tables      = {}
    }
    
    return oo(this, mt)
end

function _M:ctor()

end

function _M:setModel(modelName, modelClass)

    self.models[modelName] = modelClass
end

function _M:setTable(modelName, tableName)

    self.tables[modelName] = tableName
end

function _M:getTable(table)

    local t = self.tables[table]
    if t then return t end
    
    return table
end

function _M:getModel(model)

    local t = self.models[model]
    if t then return t end
    
    return model
end

function _M.s__.setGlobalModel(modelName, modelClass)

    static.globalModels[modelName] = modelClass
end

function _M.s__.setGlobalTable(modelName, tableName)

    static.globalTables[modelName] = tableName
end

function _M.s__.model(model)

    return static.globalModels[model] or model
end

function _M.s__.table(table)

    return static.globalTables[table] or str.last(table, '.')
end

function _M.s__.make(model, attrs)

    local model = static.model(model)

    return new(model, attrs)
end

local getModeslInfo = function(confName)

    if not confName then
        return
    end

    local config = app:conf(confName)
    if not config then
        error('invalid config')
    end

    local models = config.models
    if not models then
        error('not set models')
    end

    return models
end

function _M.s__.load(confName)

    local models = getModeslInfo(confName)
    local globalName
    for name, info in pairs(models) do
        globalName = confName .. '.' .. name
        static.setGlobalModel(globalName, info.model)
        static.setGlobalTable(globalName, info.table)
    end
end

function _M:loadConfig(confName)

    local models = getModeslInfo(confName)

    local globalName
    for name, info in pairs(models) do
        self:setModel(name, info.model)
        self:setTable(name, info.table)
        globalName = confName .. '.' .. name
        static.setGlobalModel(globalName, info.model)
        static.setGlobalTable(globalName, info.table)
    end
end

function _M.s__.init(confName)

    local configCtor = static.initedConfigs[confName]
    if configCtor then
        return configCtor
    end

    configCtor = {
        table = function(table)
            return static.table(confName .. '.' .. table)
        end,
        model = function(model)
            return static.model(confName .. '.' .. model)
        end
    }

    setmetatable(configCtor, {__index = function(this, model)
        local globalName = confName .. '.' .. model
        if static.globalModels[globalName] then
            return function(attrs)
                return static.make(confName .. '.' .. model, attrs)
            end
        else
            error('invalid model')
        end
    end})

    static.initedConfigs[confName] = configCtor

    return configCtor
end

return _M

