
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, Str = lx.kit()

local ssub, sfind = string.sub, string.find

function _M:new(tpl)

    local this = {
        tpl = tpl,
        tags = {},
        pats = {},
        cmds = {},
        nodeTypes = {},
        ntCount = 0,
    }

    oo(this, mt)

    return this
end

function _M:ctor()

    self:initBaseSet()
    self:initTags()
    self:initPats()
    self:initCmds()
    self:initNodeTypes()
    self:append()
end

function _M:append() end

function _M:initBaseSet()

    local config = app:conf('view')
    local extension = config.extension
    if extension then
        self.extension = extension
    end
    local path = config.path
    if path then
        self.path = path
    end
end

function _M:initCmds()

    local cmdList = 'include,extends,block,parent,for,endfor,' ..
        'if,else,elseif,endif,switch,case,default,endswitch,' ..
        'unless,endunless'
    self.cmds = tb.flip(cmdList, true)

end

function _M:initTags()

    local tag_sign_begin, tag_sign_end = '{', '}'
    local tag_stmt_begin, tag_stmt_end = '%', '%'
    local tag_var_begin, tag_var_end = '{', '}'
    local tag_raw_begin, tag_raw_end = ':', ':'
    local tag_lua_begin, tag_lua_end = '?', '?'
    local tag_nev_begin, tag_nev_end = '!!', '!!'
    local tag_comment_begin, tag_comment_end = '#', '#'

    local q_tag_sign_begin, q_tag_sign_end
    local q_tag_stmt_begin, q_tag_stmt_end
    local q_tag_var_begin, q_tag_var_end
    local q_tag_raw_begin, q_tag_raw_end
    local q_tag_lua_begin, q_tag_lua_end
    local q_tag_nev_begin, q_tag_nev_end
    local q_tag_comment_begin, q_tag_comment_end

    local stmt_begin, stmt_end
    local var_begin, var_end
    local raw_begin, raw_end
    local lua_begin, lua_end
    local nev_begin, nev_end
    local comment_begin, comment_end

    local q_stmt_begin, q_stmt_end
    local q_var_begin, q_var_end
    local q_raw_begin, q_raw_end
    local q_lua_begin, q_lua_end
    local q_nev_begin, q_nev_end
    local q_comment_begin, q_comment_end

    local config = app:conf('view')
    local tags = config.tags

    if tags then
        tags = tags[self.tpl.engine]
    end
    if tags then
        if tags.signBegin then tag_sign_begin = tags.signBegin end
        if tags.signEnd then tag_sign_end = tags.signEnd end

        if tags.stmtBegin then tag_stmt_begin = tags.stmtBegin end
        if tags.stmtEnd then tag_stmt_end = tags.stmtEnd end

        if tags.varBegin then tag_var_begin = tags.varBegin end
        if tags.varEnd then tag_var_end = tags.varEnd end

        if tags.rawBegin then tag_raw_begin = tags.rawBegin end
        if tags.rawEnd then tag_raw_end = tags.rawEnd end

        if tags.luaBegin then tag_lua_begin = tags.luaBegin end
        if tags.luaEnd then tag_lua_end = tags.luaEnd end

        if tags.nevBegin then tag_nev_begin = tags.nevBegin end
        if tags.nevEnd then tag_nev_end = tags.nevEnd end

        if tags.commentBegin then tag_comment_begin = tags.commentBegin end
        if tags.commentEnd then tag_comment_end = tags.commentEnd end 
    end

    local pq = Str.lregQuote

    q_tag_sign_begin, q_tag_sign_end = pq(tag_sign_begin), pq(tag_sign_end)
    q_tag_stmt_begin, q_tag_stmt_end = pq(tag_stmt_begin), pq(tag_stmt_end)
    q_tag_var_begin, q_tag_var_end = pq(tag_var_begin), pq(tag_var_end)
    q_tag_raw_begin, q_tag_raw_end = pq(tag_raw_begin), pq(tag_raw_end)
    q_tag_lua_begin, q_tag_lua_end = pq(tag_lua_begin), pq(tag_lua_end)

    q_tag_nev_begin, q_tag_nev_end = pq(tag_nev_begin), pq(tag_nev_end)

    q_tag_comment_begin, q_tag_comment_end = pq(tag_comment_begin), pq(tag_comment_end)

    stmt_begin = tag_sign_begin..tag_stmt_begin
    var_begin = tag_sign_begin..tag_var_begin
    raw_begin = tag_sign_begin..tag_raw_begin
    lua_begin = tag_sign_begin..tag_lua_begin
    nev_begin = tag_sign_begin..tag_nev_begin
    comment_begin = tag_sign_begin..tag_comment_begin

    stmt_end = tag_stmt_end..tag_sign_end
    var_end = tag_var_end..tag_sign_end
    raw_end = tag_raw_end..tag_sign_end
    lua_end = tag_lua_end..tag_sign_end
    nev_end = tag_nev_end..tag_sign_end
    comment_end = tag_comment_end..tag_sign_end

    q_stmt_begin, q_stmt_end = pq(stmt_begin), pq(stmt_end)
    q_var_begin, q_var_end = pq(var_begin), pq(var_end)
    q_raw_begin, q_raw_end = pq(raw_begin), pq(raw_end)
    q_lua_begin, q_lua_end = pq(lua_begin), pq(lua_end)
    q_nev_begin, q_nev_end = pq(nev_begin), pq(nev_end)
    q_comment_begin, q_comment_end = pq(comment_begin), pq(comment_end)

    local tags = self.tags

    tags.tag_sign_begin, tags.tag_sign_end, tags.q_tag_sign_begin, tags.q_tag_sign_end = tag_sign_begin, tag_sign_end, q_tag_sign_begin, q_tag_sign_end
    tags.tag_stmt_begin, tags.tag_stmt_end, tags.q_tag_stmt_begin, tags.q_tag_stmt_end, tags.stmt_begin, tags.stmt_end, tags.q_stmt_begin, tags.q_stmt_end = tag_stmt_begin, tag_stmt_end, q_tag_stmt_begin, q_tag_stmt_end, stmt_begin, stmt_end, q_stmt_begin, q_stmt_end
    tags.tag_var_begin, tags.tag_var_end, tags.q_tag_var_begin, tags.q_tag_var_end, tags.var_begin, tags.var_end, tags.q_var_begin, tags.q_var_end = tag_var_begin, tag_var_end, q_tag_var_begin, q_tag_var_end, var_begin, var_end, q_var_begin, q_var_end
    tags.tag_raw_begin, tags.tag_raw_end, tags.q_tag_raw_begin, tags.q_tag_raw_end, tags.raw_begin, tags.raw_end, tags.q_raw_begin, tags.q_raw_end = tag_raw_begin, tag_raw_end, q_tag_raw_begin, q_tag_raw_end, raw_begin, raw_end, q_raw_begin, q_raw_end
    tags.tag_lua_begin, tags.tag_lua_end, tags.q_tag_lua_begin, tags.q_tag_lua_end, tags.lua_begin, tags.lua_end, tags.q_lua_begin, tags.q_lua_end = tag_lua_begin, tag_lua_end, q_tag_lua_begin, q_tag_lua_end, lua_begin, lua_end, q_lua_begin, q_lua_end

    tags.tag_nev_begin, tags.tag_nev_end, tags.q_tag_nev_begin, tags.q_tag_nev_end, tags.nev_begin, tags.nev_end, tags.q_nev_begin, tags.q_nev_end = tag_nev_begin, tag_nev_end, q_tag_nev_begin, q_tag_nev_end, nev_begin, nev_end, q_nev_begin, q_nev_end

    tags.tag_comment_begin, tags.tag_comment_end, tags.q_tag_comment_begin, tags.q_tag_comment_end, tags.comment_begin, tags.comment_end, tags.q_comment_begin, tags.q_comment_end = tag_comment_begin, tag_comment_end, q_tag_comment_begin, q_tag_comment_end, comment_begin, comment_end, q_comment_begin, q_comment_end
end

function _M:initPats()
 
    local tags = self.tags
    local pats = self.pats

    pats.pat_block = tags.q_stmt_begin..'%s*endblock%s*'..tags.q_stmt_end
    pats.pat_any_syntax_begin = tags.q_tag_sign_begin
        .. '[' .. tags.q_tag_stmt_begin
        .. tags.q_tag_var_begin
        .. tags.q_tag_raw_begin
        .. tags.q_tag_lua_begin
        .. tags.q_tag_nev_begin
        .. tags.q_tag_comment_begin
        .. ']'
    pats.pat_lua_left = '%s*[^\t\r\n]-%s*'..tags.q_lua_end
    pats.pat_lua_left_code = '%s*([^\t\r\n]-)%s*'..tags.q_lua_end
    pats.pat_raw_left = '%s*[^\t\r\n]-%s*'..tags.q_raw_end
    pats.pat_raw_left_code = '%s*([^\t\r\n]-)%s*'..tags.q_raw_end
    pats.pat_var_left = "%s*[^\t\r\n]-%s*"..tags.q_var_end
    pats.pat_var_left_code = "%s*([^\t\r\n]-)%s*"..tags.q_var_end

    pats.pat_nev_left = "%s*[^\t\r\n]-%s*"..tags.q_nev_end
    pats.pat_nev_left_code = "%s*([^\t\r\n]-)%s*"..tags.q_nev_end

    pats.pat_raw_in_var = "%s*'[^']+'%s*"..tags.q_var_end
    pats.pat_raw_in_nev = "%s*'[^']+'%s*"..tags.q_nev_end
    pats.pat_stmt_left = '%s*(.*)'
    
end

function _M:initNodeTypes()

    local nt = self.nodeTypes
    local ntCount = 0

    local function range(num)
        local ret = {}
        local begin = ntCount + 1
        for i = begin, begin + num - 1 do
            ret[#ret+1] = i
            ntCount = ntCount + 1
        end
        return unpack(ret)
    end

    nt.block, nt.text, nt.expr, nt.nev, nt.block_field = range(5)
    nt.parent, nt.raw, nt.lua, nt.comment = range(4)
    nt.custom = range(1)
    nt['for'], nt.elsefor = range(2)
    nt.foreach = range(1)
    nt.forelse, nt.empty = range(2)
    nt['while'] = range(1)
    nt['if'], nt.if_first, nt.if_elseif, nt.if_else = range(4)
    nt.unless = range(1)
    nt.switch, nt.switch_first, nt.switch_case, nt.switch_default = range(4)
    nt['break'], nt.continue = range(2)
    nt.include = range(1)
    nt.set = range(1)
    nt.each = range(1)
    
    local custom = self.tpl.custom
    local nts = custom.nts
    if #nts > 0 then
        for _, v in ipairs(nts) do
            nt[v] = range(1)
        end
    end

    self.ntCount = ntCount
end


return _M

