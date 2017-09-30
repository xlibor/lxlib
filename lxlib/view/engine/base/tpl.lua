
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, Str, new = lx.kit()
local use, try, throw = lx.kit2()

local tconcat = table.concat

function _M:new(engine, view, namespace, blocks)

    local this = {
        engine = engine,
        lineno = 0,
        args = {},
        nodeRoot = nil,
        blocks = blocks,
        view = view,
        namespace = namespace,
        context = {},
        isSubTpl = false,
        nodeCount = 0,
        lastBlock = nil,
        ast_node = {
            nodeType = 1, 
            child = {},
            parent = nil,
            lno = 0,
            content = '',
            valid = nil,
            tplIdx = 1
        }
    }
     
    oo(this, mt)

    this.custom = app:make('view.'..engine..'.custom', this)
    this.config = app:make('view.'..engine..'.config', this)
    this.parser = app:make('view.'..engine..'.parser', this)
    this.compiler = app:make('view.'..engine..'.compiler', this)
    this.loader = app:make('view.'..engine..'.loader', this)

    this:initTpls(this, self)
    
    return this
end

function _M:ctor()

end

function _M:initTpls(new, old)

    if old then
        local tpls = old.tpls
        tapd(tpls, new)
        new.tpls = tpls
        new.tplIdx = #tpls
    else
        new.tpls = {new}
        new.tplIdx = 1
    end
end

function _M:parse()

    try(function()
        self.parser:parse()
    end)
     :catch(function(e)
        throw('viewParseException', self, e)
    end)
     :run()
end

function _M:compile()

    local blocks
 
    self.compiler:compileBlock(self.nodeRoot)
 
    local strCode = tconcat(self.compiler.output, '')
    self.strCode = strCode
    -- echo(strCode)
end

function _M:preload()

    local strCode = self.strCode

    local bitCode
    
    try(function()
        bitCode = assert(loadstring(strCode))
    end)
    :catch(function(e)
        throw('viewPreloadException', self, e)
    end):run()

    self.bitCode = bitCode
end

function _M:load()

    self.loader:load()
end

function _M:prepare()

    self:load()

    self:parse()
 
    self:compile()

end

function _M:render(context, prepared, env)
     
    self.context = context
     
    if not prepared then
        self:prepare()
        self:preload()
    end

    local blocks = self.blocks
    local bitCode = self.bitCode

    if env then
        env:mergeContext(context)
    else
        env = app:make('view.'..self.engine..'.env', self, context, blocks)
    end

    setfenv(bitCode, env)

    local ok = 
    try(function()
        bitCode()
    end)
    :catch('viewException', function(e)
        throw(e)
    end, true)
    :catch(function(e)

        throw('viewRenderException', self, e)
    end):run()

    local ret
    if ok then
        ret = tconcat(env.___, '')
    else
        ret = ''
    end

    return ret
end

return _M

