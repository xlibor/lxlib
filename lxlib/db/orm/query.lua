
local lx, _M, mt = oo{
    _cls_    = '',
    _static_ = {

    }
}

local app, lf, tb, str, new = lx.kit()
local use, try, throw = lx.kit2()
local split, join = str.split, str.join
local sfind, slen = string.find, string.len
local count = tb.count

local passthru = tb.l2d{
    'insert', 'insertGetId', 'getBindings', 'getSql',
    'exists', 'count', 'min', 'max', 'avg', 'sum', 'getConnection'
}

local redirects = tb.l2d{
    'join', 'exp'
}

local Relation      = use 'relation'
local Paginator     = use 'paginator'
local static

function _M._init_(this)

    static = this.static
end

function _M:new(builder)

    local this = {
        builder = builder,
        scopes = {},
        _onDelete = false,
        eagerLoad = {},
        removedScopes = {},
    }

    setmetatable(this, mt)

    return this
end

function _M:getModel()

    return self.model
end

function _M:setModel(model)

    self.model = model

    -- self.builder = app:db():table(model:getTable())

    return self
end

function _M:getModels(...)

    local results = self.builder:get(...)

    local conn = self.model:getConnName()

    return self.model:hydrate(results, conn)
end

function _M:getQuery()

    return self.builder
end

_M.getBuilder = _M.getQuery

function _M:withGlobalScope(id, scope)

    self.scopes[id] = scope
    if lf.isObj(scope) then
        local func = scope.extend
        if func then
            scope:extend(self)
        end
    end

    return self
end

function _M:withoutGlobalScope(scope)

    if lf.isObj(scope) then
        scope = scope.__nick
    end

    self.scopes[scope] = nil

    tapd(self.removedScopes, scope)

    return self
end

function _M:withoutGlobalScopes(scopes)

    if lf.isTbl(scopes) then
        for _, scope in ipairs(scopes) do
            self:withoutGlobalScope(scope)
        end
    else
        self.scopes = {}
    end

    return self
end

_M.pure = _M.withoutGlobalScopes

function _M:get(...)

    local query = self:applyScopes()
    local models = query:getModels(...)

    if #models > 0 then

        models = query:eagerLoadRelations(models)
    end

    static.setModelsMt(models)

    return models
end

function _M:where(column, ...)

    self.builder:where(column, ...)

    return self
end

function _M:orWhere(column, ...)

    self.builder:orWhere(column, ...)

    return self
end

_M.or_ = _M.orWhere

function _M:first(...)

    local models = self:take(1):get(...)

    if #models > 0 then
        return models[1]
    end
end

function _M:firstOrFail(...)

    local model = self:first(...)

    if model then
        return model
    else
        throw('modelNotFoundException', self.model.__cls)
    end
end

function _M:find(id, ...)

    if lf.isTbl(id) then
        return self:findMany(id, ...)
    end

    local keyName = self.model:getQualifiedKeyName()

    self.builder:where(keyName, '=', id)

    return self:first(...)
end

function _M:findOrFail(id, ...)

    local result = self:find(id, ...)
    if result then
        return result
    else
        throw('modelNotFoundException', self.model.__cls)
    end
end

function _M:toBase()

    return self:applyScopes():getBuilder()
end

function _M:getBuilder()

    return self.builder
end

function _M:setBuilder(builder)

    self.builder = builder

    return self
end

function _M:pluck(column, key)

    local results = self:toBase():pluck(column, key)
 
    if (not self.model:hasGetMutator(column) and
        not self.model:hasCast(column) and
        not tb.contains(self.model:getDates(), column)) then

        return results
    end

    return tb.map(results, function(value)

        return self.model:newFromBuilder({[column] = value}).column
    end)
end

function _M:with(...)

    local relations = lf.needArgs(...)

    local eagers = self:parseWithRelations(relations)

    self.eagerLoad = tb.merge(self.eagerLoad, eagers)

    return self
end

function _M:without(...)

    local relations = lf.needArgs(...)

    self.eagerLoad = tb.diffKey(self.eagerLoad, tb.flip(relations))

    return self
end

function _M:withCount(...)

    local query
    local relation

    if self.builder:selectedCount() == 0 then
        self:select('*')
    end

    local relations = lf.needArgs(...)

    for name, constraints in pairs(self:parseWithRelations(relations)) do

        relation = self:getHasRelationQuery(name)

        query = relation:getRelationCountQuery(
            relation:getRelated():newQuery(), self
        )

        query:callScope(constraints)

        query:mergeModelDefinedRelationConstraints(relation:getQuery())

        self:selectSub(query:toBase(), str.snake(name) .. '_count')
    end
    
    return self
end

function _M.__:getHasRelationQuery(relation)

    return Relation.noConstraints(function()
        local model = self:getModel()

        return lf.call{model, relation}
    end)
end

function _M:mergeModelDefinedRelationConstraints(relation)

    local removedScopes = relation.removedScopes
    local relationQuery = relation:getQuery()

    return self:withoutGlobalScopes(removedScopes)
        :mergeWheres(relationQuery:getWheres())
end

function _M.__:parseWithRelations(relations)

    local results = {}
    local f
 
    for name, constraints in pairs(relations) do
        if lf.isNum(name) then
            f = function ()    
            end
            name = constraints
            constraints = f
        end

        results = self:parseNestedWith(name, results)

        results[name] = constraints
    end

    return results
end

function _M.__:parseNestedWith(name, results)

    local progress = {}
    local last

    for _, segment in ipairs(split(name, '.')) do 
        tapd(progress, segment)
        last = join(progress, '.')

        if not results[last] then
            results[last] = function () 
                
            end
        end
    end

    return results
end

function _M.__:loadRelation(models, name, constraints)

    local relation = self:getRelation(name)

    relation:addEagerConstraints(models)

    constraints(relation)

    models = relation:initRelation(models, name)

    local results = relation:getEager()

    return relation:match(models, results, name)
end

function _M:getRelation(name)

    local relation = Relation.noConstraints(function()
        local ok, t = 
        try(function()

            return lf.call{self:getModel(), name}
        end)
        :catch('badMethodCallException', function(e)

            throw('relationNotFoundException', self:getModel(), name)
        end):run()

        if ok then return t end
    end)
 
    local nested = self:nestedRelations(name)
 
    if count(nested) > 0 then
        relation:getQuery():with(nested)
    end

    return relation
end

function _M.__:nestedRelations(relation)

    local nested = {}
    
    local t
    for name, constraints in pairs(self.eagerLoad) do
        if self:isNested(name, relation) then
            t = str.sub(name, slen(relation..'.') + 1)
            nested[t] = constraints
        end
    end

    return nested
end

function _M.__:isNested(name, relation)

    local dots = str.contains(name, '.')

    return dots and str.startsWith(name, relation..'.')
end

function _M:getEagerLoads()

    return self.eagerLoad
end

function _M:setEagerLoads(eagerLoad)

    self.eagerLoad = eagerLoad

    return self
end

function _M:eagerLoadRelations(models)

    local eagerLoad = self.eagerLoad
    if eagerLoad then 
        for name, constraints in pairs(eagerLoad) do
            if not sfind(name, '%.') then

                models = self:loadRelation(models, name, constraints)
            end
        end
    end

    return models
end

function _M.__:callScope(scope, ...)
 
    local model = self.model
    local func

    if lf.isFun(scope) then
        func = scope
    else
        func = model[scope]
    end

    local ret = func(model, self, ...) or self

    return ret
end

function _M:applyScope(scope, query)

    if lf.isFun(scope) then
        scope(query)
    elseif scope:__is 'scope' then
        scope:apply(query, self:getModel())
    end
end

function _M:applyScopes()

    if not next(self.scopes) then
        return self 
    end

    local query = self:__clone()

    for _, scope in pairs(self.scopes) do
        self:applyScope(scope, query)
    end

    return query
end

function _M:increment(column, amount, extra)

    amount = amount or 1
    extra = extra or {}
    extra = self:addUpdatedAtColumn(extra)
    
    return self:toBase():increment(column, amount, extra)
end

function _M:decrement(column, amount, extra)

    amount = amount or 1
    extra = extra or {}
    extra = self:addUpdatedAtColumn(extra)
    
    return self:toBase():decrement(column, amount, extra)
end

function _M.__:addUpdatedAtColumn(values)

    if not self.model:useTimestamps() then
        
        return values
    end
    local column = self.model:getUpdatedAtColumn()
    
    return tb.add(values, column, self.model:freshTimestampString())
end

function _M:paginate(perPage, columns, pageName, page)

    pageName = pageName or 'page'
    columns = columns or {'*'}

    page = page or Paginator.resolveCurrentPage(pageName)

    perPage = perPage or self.model:getPerPage()
    local query = self:toBase()

    local total = query:getCountForPagination()

    local results = self:page(page, perPage):get()
    
    return new('lengthAwarePaginator', results, total, perPage,
        page, {
            path = Paginator.resolveCurrentPath(), pageName = pageName
        }
    )
end

_M.paging = _M.paginate

function _M:simplePaginate(perPage, columns, pageName, page)

    pageName = pageName or 'page'
    columns = columns or {'*'}
    page = page or Paginator.resolveCurrentPage(pageName)
    perPage = perPage or self.model:getPerPage()
    self:skip((page - 1) * perPage):take(perPage + 1)
    
    return new('paginator' ,self:get(columns), perPage, page, {path = Paginator.resolveCurrentPath(), pageName = pageName})
end

function _M:delete()

    if self._onDelete then
        
        return lf.call(self._onDelete, self)
    end
    
    return self:toBase():delete()
end

function _M:forceDelete()

    return self.builder:delete()
end

function _M:onDelete(callback)

    self._onDelete = callback
end

local function modelsToCol(models)

    return app:make('modelCol', models)
end

local function modelsToAutoDeriveCol(models)

    local col = app:make('modelCol', models)
    col.autoDerive = true

    return col
end

local function modelsIndex(models, key)
    
    if key == 'col' then
        return modelsToCol
    elseif key == 'Col' then
        return modelsToAutoDeriveCol
    elseif key == 'count' then
        return function()
            return #models
        end
    end
end

function _M.s__.setModelsMt(models)

    if lf.isTbl(models) then
        setmetatable(models, {
            __index = modelsIndex
        })
    end
end

function _M:_clone_(newObj)

    newObj.builder = self.builder:__clone()
end

function _M:_run_(method)

    local builder = rawget(self, 'builder')
    if not builder then
        error('builder not inited')
    end
    local func

    local model = rawget(self, 'model')
    if not model then
        error('model not inited')
    end

    local scope = 'scope' .. str.ucfirst(method)

    if model:__has(scope) then
        return function(self, ...)
            return self:callScope(scope, ...)
        end, true
    end

    if passthru[method] then
        return function(self, ...)
            builder = self:toBase()
            return lf.call({builder, method}, ...)
        end
    end

    if redirects[method] then
        return function(self, ...)
            builder = rawget(self, 'builder')
            return lf.call({builder, method}, ...)
        end
    end

    if builder:__has(method) then
        return function(self, ...)
            builder = rawget(self, 'builder')
            func = builder[method]
            func(builder, ...)

            return self
        end
    else
        error('no mehtod:' .. method)
    end
end

return _M

