
local _M = {
    _cls_    = ''    
}

local mt = {__index = _M}

local lx = require('lxlib')
local app, lf, tb, Str = lx.kit()

local tags, pats, nt

local tconcat, tremove = table.concat, table.remove
local split = Str.split

local ssub, sgsub, sfind, smatch, sgmatch = string.sub, string.gsub, string.find, string.match, string.gmatch
local slower, supper = string.lower, string.upper

function _M:new(tpl)

    local this = {
        tpl = tpl
    }

    setmetatable(this, mt)

    if not tags then
        this:loadConfig()
    end

    return this
end

function _M:loadConfig()

    local cfg = self.tpl.config
    nt = cfg.nodeTypes
    pats = self.tpl.config.pats
    tags = self.tpl.config.tags

    _M.pats = pats
    _M.tags = tags
    _M.nt = nt
end

local function cloneNode(src)

    local ret = {}
    for k, v in pairs(src) do 
        if type(v) == "table" then 
            ret[k] = cloneNode(v) 
        else    
            ret[k] = v 
        end
    end

    return ret
end

function _M:parse()

    local srclines = self.tpl.srclines    
    local node
    local extendFrom
    if not self.tpl.blocks then
        self.tpl.blocks = {__root = self:addAstNode(nt.block, nil, '__root')}
    end

    local curBlock = self.tpl.blocks.__root
    local currParent = curBlock

    local curText = self:addAstNode(nt.text, currParent, '')
    self.tpl.nodeRoot = currParent
    
    local cur_lno = 1
    local pos_s, pos_e, pos_tmp, t_pos_s, t_pos_e
    local last = 1
    local i, j, t, ok
    local bstack = {}
    local pre, word, cmd, arglist
    local skip_lua, skip_comment, skip_verbatim = 0, 0, 0
    local lastNodeType = 0
    local content
    local node_sub, node_member, nodeParent
    local signDisable
    local skips

    tapd(bstack, currParent)

    for lno, text in ipairs(srclines) do
        while (last <= #text) do
            signDisable = false

            if skip_comment == 1 then
                i, j = sfind(text, tags.q_comment_end, last)
                if i == nil then
                    break
                else
                    skip_comment = 0
                    last = j + 1
                end
            end

            if skip_verbatim == 1 then
                i, j = sfind(text, pats.q_verbatim_end, last)
                if i == nil then
                    curText.content = curText.content .. ssub(text, last)
                    last = 1

                    break
                else
                    skip_verbatim = 0
                    last = j + 1
                end
            end

            if skip_lua == 1 then
                i, j = sfind(text, pats.pat_lua_left, last)
                if i == nil then
                    node.content = node.content .. ssub(text, last)
                    last = 1

                    break
                else
                    skip_lua = 0
                    word = smatch(text, pats.pat_lua_left_code, i, j - 2)
                    node.content = node.content .. word
                    last = j + 1
                end
            end

            pos_s, pos_e = sfind(text, pats.pat_any_syntax_begin, last)
            if pos_s then
                if tags.stmt_end == '' then
                    t_pos_s, t_pos_e = sfind(text, tags.q_stmt_begin .. [[%w+]], last)
                    if t_pos_s then
                        pos_s, pos_e = t_pos_s, t_pos_s
                    end
                end
                if not t_pos_s then
                    t = ssub(text, pos_s - 1, pos_s - 1)
                    if t == '@' then
                        signDisable = true
                        pos_s = pos_s - 1
                    end
                end
            else
                if tags.stmt_end == '' then
                    pos_s, pos_e = sfind(text, tags.q_stmt_begin, last)
                end
                if pos_s == nil then
                    if #(curText.content) < 1000 then
                        curText.content = curText.content .. ssub(text, last)
                    else
                        tapd(currParent.child, curText)    
                        curText = self:addAstNode(nt.text, currParent, ssub(text, last))
                    end

                    break
                end 
            end
 
            curText.content = curText.content .. ssub(text, last, pos_s - 1)

            tapd(currParent.child, curText)    
            curText = self:addAstNode(nt.text, currParent, '')

            pre = ssub(text, pos_s, pos_e)
            last = pos_e + 1

            if signDisable then
                i, j = sfind(text, '.*'..tags.q_tag_sign_end, last)

                word = smatch(text, '(.*'..tags.q_tag_sign_end..')', pos_s + 1, j)
                node = self:addAstNode(nt.raw, currParent, word)
                last = j + 1
                tapd(currParent.child, node)
            elseif pre == tags.comment_begin then
                skip_comment = 1
            elseif pre == tags.lua_begin then
                i, j = sfind(text, pats.pat_lua_left, last) 
                if i ~= last then
                    skip_lua = 1
                    node = self:addAstNode(nt.lua, currParent, '')
                    tapd(currParent.child, node)
                    last = last + 1
                else
                    word = smatch(text, pats.pat_lua_left_code, i, j - 2)
                    node = self:addAstNode(nt.lua, currParent, word)
                    last = j + 1
                    tapd(currParent.child, node)
                end
            elseif pre == tags.raw_begin then
                i, j = sfind(text, pats.pat_raw_left, last) 
                if i ~= last then return self:setErr("expr error") end
                word = smatch(text, pats.pat_raw_left_code, i, j - 2)
                node = self:addAstNode(nt.raw, currParent, word)
                last = j + 1
                tapd(currParent.child, node)
            elseif pre == tags.var_begin then
                i, j = sfind(text, pats.pat_raw_in_var, last)
                if i == last then
                    word = smatch(text, "'[^']+'", i, j-2)    
                    node = self:addAstNode(nt.raw, currParent, ssub(word, 2, -2))
                else
                    i, j = sfind(text, pats.pat_var_left, last) 
                    if i ~= last then return self:setErr("expr error") end
                    word = smatch(text, pats.pat_var_left_code, i, j-2)
                    node = self:addAstNode(nt.expr, currParent, word)
                end
                last = j + 1
                tapd(currParent.child, node)
            elseif pre == tags.nev_begin then
                i, j = sfind(text, pats.pat_raw_in_nev, last)
                if i == last then
                    word = smatch(text, "'[^']+'", i, j-2)    
                    node = self:addAstNode(nt.raw, currParent, ssub(word, 2, -2))
                else
                    i, j = sfind(text, pats.pat_nev_left, last) 
                    if i ~= last then return self:setErr("expr error") end
                    word = smatch(text, pats.pat_nev_left_code, i, j-2)
                    node = self:addAstNode(nt.nev, currParent, word)
                end
                last = j + 1
                tapd(currParent.child, node)
            elseif pre == tags.stmt_begin then
                if tags.stmt_end ~= '' then
                    i, j = sfind(text, ".-"..tags.q_stmt_end, last)
                    if i ~= last then return self:setErr("command error") end
                    t = ssub(text, i, j - 2)
                else
                    i, j = sfind(text, "[%w_]+%s+.*", last)
                    if not i or i ~= last then

                        i, j = sfind(text, '[%w_]+%(.*%)', last)
                    end
                    if not i then
                        t = ssub(text, last - 1)
                        node = self:addAstNode(nt.raw, currParent, t)
                        tapd(currParent.child, node)
                        break
                    end
                    t = ssub(text, i, j)
                end
 
                last = j + 1

                ok, currParent, skips = self:parseCmd(t, bstack, currParent)
                if skips then
                    if skips.skip_comment then skip_comment = skips.skip_comment end
                    if skips.skip_verbatim then skip_verbatim = skips.skip_verbatim end 
                end
                if not ok then
                    self.tpl.lineno = cur_lno
                    cmd = currParent
                    if cmd == 'media' then
                        currParent = bstack[#bstack]
                        t = ssub(text, i - 1, j)
                        node = self:addAstNode(nt.raw, currParent, t)
                        tapd(currParent.child, node)
                        break
                    else
                        return self:setErr("unknown command type:" .. cmd)
                    end
                end
            end
        end

        cur_lno = cur_lno + 1
        self.tpl.lineno = cur_lno
        last = 1
    end

    tapd(currParent.child, curText)

    if #bstack > 1 then
        return self:printNode(bstack[#bstack], "unmatch block")
    end
    
    return 0
end

function _M:printNode(node, prefix)

    local content = node.content[1]
     
    content = content or 'unknown'

    self:setErr(prefix..' "'..content..'"', node.lno)

end

function _M:parseCmd(text, bstack, currParent)

    local i, j, cmd, other = sfind(text, '([%w_]+)([%(%s]?)')
    if not i then
        self:setErr("command syntax error")
    end

    if not other then
        j = j + 1
    end
    text = ssub(text, j) or ''
    local arglist = {}

    local method = self['parse_cmd_'..cmd]

    if not method then
        local custom = self.tpl.custom
        local customParsers = custom.parsers
        method = customParsers[cmd]
        if method then
            return true, method(self, currParent, arglist, text, bstack)
        else
            if custom.customs[cmd] then
                return true, self:parse_cmd_custom(cmd, bstack, currParent, arglist, text)
            end
        end
    end

    if method then
        return true, method(self, cmd, bstack, currParent, arglist, text)
    else
        return false, cmd
    end
end

function _M:checkEndStmt(cmd, text)

    if sfind(text, '[^%s%c]+') then
        self:setErr('unnecessary str after '..cmd)
    end
end

function _M:parse_cmd_custom(cmd, bstack, currParent, arglist, text)

    local t = self:getStmtLeft(cmd, text)
    arglist[1] = cmd
    arglist[2] = t

    local node
    node = self:addAstNode(nt.custom, currParent, arglist)
    tapd(currParent.child, node)

    return currParent
end

function _M:parse_cmd_for(cmd, bstack, currParent, arglist, text)

    for kv, range in sgmatch(text, "%s*([%w_]+,?%s*[%w_]*)%s+in%s+(.*)") do
        tapd(arglist, kv)
        tapd(arglist, range)
    end

    local node
    node = self:addAstNode(nt['for'], currParent, arglist)
    tapd(currParent.child, node)
    currParent = node
    tapd(bstack, node)

    return currParent
end

function _M:parse_cmd_include(cmd, bstack, currParent, arglist, text)

    local t = self:getStmtLeft(cmd, text)
    local tplName, context
    if sfind(t, ',') then

        t = Str.split(t, ',', 2)
        tplName, context = t[1], t[2]
        context = Str.trim(context,' ')
        context = ssub(context, 2, -2)
        context = Str.trim(context,' ;')

    else
        tplName = t
    end

    tplName = Str.trim(tplName, ' "\'')

    arglist[1] = tplName; arglist[2] = context

    local node
    node = self:addAstNode(nt.include, currParent, arglist)
    tapd(currParent.child, node)

    return currParent
end

function _M:parse_cmd_while(cmd, bstack, currParent, arglist, text)

    local t = self:getStmtLeft(cmd, text)
    arglist[1] = t

    local node
    node = self:addAstNode(nt['while'], currParent, arglist)
    tapd(currParent.child, node)
    currParent = node
    tapd(bstack, node)

    return currParent
end

function _M:parse_cmd_endwhile(cmd, bstack, currParent, arglist, text)
    
    self:checkEndStmt(cmd, text)

    local node

    if #bstack < 1 or bstack[#bstack].nodeType ~= nt['while'] then
        return self:setErr("endwhile syntax error") 
    end
    tremove(bstack)
    currParent = bstack[#bstack]

    return currParent
end

function _M:parse_cmd_endfor(cmd, bstack, currParent, arglist, text)
    
    self:checkEndStmt(cmd, text)

    local node

    if #bstack < 1 or bstack[#bstack].nodeType ~= nt['for'] then
        return self:setErr("endfor syntax error") 
    end
    tremove(bstack)
    currParent = bstack[#bstack]

    return currParent
end

function _M:parse_cmd_break(cmd, bstack, currParent, arglist, text)
    
    local t = self:getStmtLeft(cmd, text)
    arglist[1] = t

    local parent = currParent
    local nodeLoop
    while parent do 
        if parent.nodeType == nt['for']
            or parent.nodeType == nt.foreach
            or parent.nodeType == nt.forelse
            or parent.nodeType == nt['while'] then

            nodeLoop = parent
            break
        end
        parent = parent.parent
    end

    local node
    node = self:addAstNode(nt['break'], currParent, arglist)
    node.relatedNode = nodeLoop
    tapd(currParent.child, node)

    return currParent
end

function _M:parse_cmd_continue(cmd, bstack, currParent, arglist, text)
    
    local t = self:getStmtLeft(cmd, text)
    arglist[1] = t

    local parent = currParent
    local nodeLoop
    while parent do 
        if parent.nodeType == nt['for']
            or parent.nodeType == nt.foreach
            or parent.nodeType == nt.forelse
            or parent.nodeType == nt['while'] then
            
            nodeLoop = parent
            break
        end
        parent = parent.parent
    end

    local node
    if nodeLoop then
        nodeLoop.hasContinue = true
        node = self:addAstNode(nt['continue'], currParent, arglist)
        node.relatedNode = nodeLoop
        tapd(currParent.child, node)
    else
        self:setErr('no for-node parent for continue statement')
    end

    return currParent
end

function _M:getStmtLeft(cmd, s)

    local t

    if ssub(s, 1, 1) == '(' and ssub(s, -1) == ')' then
        t = ssub(s, 2, -2)
    else
        t = smatch(s, "%s*(.*)")
    end

    return t
end

function _M:parse_cmd_unless(cmd, bstack, currParent, arglist, text)

    local node, node_sub

    local t = self:getStmtLeft(cmd, text)

    arglist[1] = t

    node = self:addAstNode(nt.unless, currParent, arglist)
    tapd(currParent.child, node)
    currParent = node
    tapd(bstack, node)

    return currParent
end

function _M:parse_cmd_if(cmd, bstack, currParent, arglist, text)

    local node, node_sub

    local t = self:getStmtLeft(cmd, text)

    arglist[1] = t

    node = self:addAstNode(nt['if'], currParent, arglist)
    tapd(currParent.child, node)
    node_sub = self:addAstNode(nt.if_first, node, arglist)
    tapd(node.child, node_sub)
    currParent = node_sub
    tapd(bstack, node_sub)

    return currParent
end

function _M:parse_cmd_elseif(cmd, bstack, currParent, arglist, text)

    local node, lastNodeType, nodeParent

    local t = self:getStmtLeft(cmd, text)
    arglist[1] = t

    lastNodeType = bstack[#bstack].nodeType
    if #bstack < 1 or self:invalidNtRange(
        lastNodeType, nt.if_first, nt.if_elseif) then

        return self:setErr("else syntax error ")
    end
    nodeParent = currParent.parent
    node = self:addAstNode(nt.if_elseif, nodeParent, arglist)
    tapd(nodeParent.child, node)
    currParent = node
    tremove(bstack)
    tapd(bstack, node)

    return currParent
end

function _M:parse_cmd_else(cmd, bstack, currParent, arglist, text)

    self:checkEndStmt(cmd, text)

    local node, lastNodeType, nodeParent

    lastNodeType = bstack[#bstack].nodeType
    if #bstack < 1 or self:invalidNtRange(
        lastNodeType, nt.if_first, nt.if_elseif) then

        return self:setErr("else syntax error ")
    end
    nodeParent = currParent.parent
    node = self:addAstNode(nt.if_else, nodeParent, arglist)
    tapd(nodeParent.child, node)
    currParent = node
    tremove(bstack)
    tapd(bstack, node)

    return currParent
end

function _M:parse_cmd_endif(cmd, bstack, currParent, arglist, text)
    
    self:checkEndStmt(cmd, text)

    local node, lastNodeType

    lastNodeType = bstack[#bstack].nodeType
    if #bstack < 1 or self:invalidNtRange(
        lastNodeType, nt['if'], nt.if_else) then

        return self:setErr("endif syntax error")
    end

    tremove(bstack)    
    currParent = bstack[#bstack]

    return currParent
end

function _M:parse_cmd_endunless(cmd, bstack, currParent, arglist, text)
    
    self:checkEndStmt(cmd, text)

    local node, lastNodeType

    tremove(bstack)    
    currParent = bstack[#bstack]

    return currParent
end

function _M:parse_cmd_switch(cmd, bstack, currParent, arglist, text)

    local t = self:getStmtLeft(cmd, text)
    arglist[1] = t

    local node, node_sub
    node = self:addAstNode(nt.switch, currParent, arglist)
    tapd(currParent.child, node)
    node_sub = self:addAstNode(nt.switch_first, node, arglist)
    tapd(node.child, node_sub)
    currParent = node_sub
    tapd(bstack, node_sub)

    return currParent
end

function _M:parse_cmd_case(cmd, bstack, currParent, arglist, text)

    local t = self:getStmtLeft(cmd, text)
    arglist[1] = t

    local node, lastNodeType, nodeParent
    lastNodeType = bstack[#bstack].nodeType
    if #bstack < 1 or self:invalidNtRange(
        lastNodeType, nt.switch, nt.switch_default) then

        return self:setErr("switch case syntax error ")
    end
    nodeParent = currParent.parent
    node = self:addAstNode(nt.switch_case, nodeParent, arglist)
    tapd(nodeParent.child, node)
    currParent = node
    tremove(bstack)
    tapd(bstack, node)

    return currParent
end

function _M:parse_cmd_default(cmd, bstack, currParent, arglist, text)

    local node, lastNodeType, nodeParent
    lastNodeType = bstack[#bstack].nodeType
    if #bstack < 1 or self:invalidNtRange(
        lastNodeType, nt.switch, nt.switch_case) then
        return self:setErr("switch default syntax error ")
    end
    nodeParent = currParent.parent
    node = self:addAstNode(nt.switch_default, nodeParent, arglist)
    tapd(nodeParent.child, node)
    currParent = node
    tremove(bstack)
    tapd(bstack, node)

    return currParent
end

function _M:invalidNtRange(nodeType, begin, over)

    return (nodeType < begin or nodeType > over)
end

function _M:parse_cmd_endswitch(cmd, bstack, currParent, arglist, text)
    
    self:checkEndStmt(cmd, text)

    local node, lastNodeType
    lastNodeType = bstack[#bstack].nodeType
    if #bstack < 1 or self:invalidNtRange(
        lastNodeType, nt.switch, nt.switch_default) then

        return self:setErr("endswitch syntax error ")
    end
    tremove(bstack)    
    currParent = bstack[#bstack]

    return currParent
end

function _M:parse_cmd_extends(cmd, bstack, currParent, arglist, text)

    local t = self:getStmtLeft(cmd, text)
    arglist[1] = t

    local tpl = self.tpl

    local node
    if tpl.involved_file ~= nil then
        return self:setErr("extends duplicated: ")
    end
    if currParent.content ~= "__root"
        or #currParent.child > 2
        or #bstack > 1 then

        return self:setErr("extends error: ")
    end

    tpl.isSubTpl = true
    local parent = Str.trim(arglist[1],  ' "\'')
    tpl.extendsFrom = parent

    local parentTpl = tpl:new(tpl.engine, parent, tpl.namespace, tpl.blocks)
    parentTpl:load()
    parentTpl:parse()

    return currParent
end

function _M:parse_cmd_set(cmd, bstack, currParent, arglist, text)

    local t = self:getStmtLeft(cmd, text)
    arglist[1] = t

    local node
    local i, j = sfind(text, "=")
    if i then
        node = self:addAstNode(nt.set, currParent, arglist)
        tapd(currParent.child, node)
    else
        node = self:addAstNode(nt.set, currParent, arglist)
        tapd(currParent.child, node)
        currParent = node
        tapd(bstack, node)
    end

    return currParent
end

function _M:parse_cmd_endset(cmd, bstack, currParent, arglist, text)
    
    self:checkEndStmt(cmd, text)

    local node
    tremove(bstack)    
    currParent = bstack[#bstack]

    return currParent
end

function _M:parse_cmd_verbatim(cmd, bstack, currParent, arglist, text)

    self:checkEndStmt(cmd, text)

    local node
    node = self:addAstNode(nt.raw, currParent, '')
    tapd(currParent.child, node)

    return currParent, {skip_verbatim = 1}
end

function _M:addAstNode(ntype, parent, content)
    
    local tpl = self.tpl

    if type(ntype) == 'string' then
        local t = nt[ntype]
        if not t then
            error('invalid node type:'..(ntype or ''))
        else
            ntype = t
        end
    end

    local node = cloneNode(self.tpl.ast_node)
    node.parent = parent
    node.nodeType = ntype
    node.content = content
    node.lno = self.tpl.lineno
    node.tplIdx = tpl.tplIdx or 1
    node.index = tpl.nodeCount
    tpl.nodeCount = tpl.nodeCount + 1

    return node
end

_M.addNode = _M.addAstNode

function _M:getNt()

    return nt
end

function _M:setErr(des, lineno)

    lineno = lineno or self.tpl.lineno
    local errStr = des..' in file:"'..self.tpl.curFile..
        '", near line:'..lineno

    self.tpl.errInfo = errStr
    error(des)

end

return _M

