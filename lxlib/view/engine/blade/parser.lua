
local lx, _M = oo{
    _cls_ = '',
    _ext_ = {path = 'lxlib.view.engine.base.parser'}
}

local app, lf, tb, Str = lx.kit()

local tconcat, tremove = table.concat, table.remove
local split = Str.split

local ssub, sgsub, sfind, smatch, sgmatch = string.sub, string.gsub, string.find, string.match, string.gmatch
local slower, supper = string.lower, string.upper

local nt

function _M:ctor()

    if not nt then
        local cfg = self.tpl.config
        nt = cfg.nodeTypes
    end
end

local function cloneNode(src, notDeep)

    local deep = not notDeep
    local ret = {}
    for k, v in pairs(src) do 
        if type(v) == "table" and deep then 
            ret[k] = cloneNode(v) 
        else
            ret[k] = v 
        end
    end

    return ret
end

function _M:copyBlock(oldBlock, newBlock)

    newBlock.fields = oldBlock.fields
    newBlock.appendable = oldBlock.appendable

end

function _M:parse_cmd_each(cmd, bstack, currParent, arglist, text)

    local t = self:getStmtLeft(cmd, text)
    local tplName, loopTarget, eachVar, emptyTpl
    if sfind(t, ',') then
        t = Str.split(t, ',', 4)
        tplName, loopTarget, eachVar, emptyTpl = t[1], t[2], t[3], t[4]
        tplName = Str.trim(tplName, " '\"")
        loopTarget = Str.trim(loopTarget, " ")
        eachVar = Str.trim(eachVar, " '\"")
        if emptyTpl then
            emptyTpl = Str.trim(emptyTpl, " '\"")
        end
    else
        error('invalid each cmd info')
    end

    arglist[1] = tplName; arglist[2] = loopTarget
    arglist[3] = eachVar; arglist[4] = emptyTpl

    local node
    node = self:addAstNode(nt.each, currParent, arglist)
    tapd(currParent.child, node)

    return currParent
end

function _M:parse_cmd_section(cmd, bstack, currParent, arglist, text)

    local default
    local t
    if cmd == 'yield' then
        t = smatch(text, "%((.-)%)")
    else
        t = smatch(text, "%((.*)%)")
    end

    if sfind(t, ',') then
        local t1, t2 = smatch(t, "['\"]([%w_]+)['\"],%s*(.*)")
        arglist[1], arglist[2] = t1, t2
        t = t1; default = t2
    else
        t = Str.trim(t, "'\"")
        arglist[1] = t
    end

    local block
    local sectionName = t

    self.tpl.lastBlock = sectionName

    local parentBlock = self.tpl.blocks[sectionName]
    if parentBlock then
        block = self:addAstNode(nt.block, currParent, sectionName)
        self:copyBlock(parentBlock, block)
    else
        block = self:addAstNode(nt.block, currParent, sectionName)
        block.appendable = true
        self.tpl.blocks[sectionName] = block
    end

    if not block.fields then
        block.fields = {}
    end

    local field
    if cmd == 'yield' then
        block.showable = true
        if default then
            block.default = self:addAstNode(nt.expr, currParent, default)
        end
        tapd(currParent.child, block)
    else
        tapd(currParent.child, block)
        field = self:addAstNode(nt.block_field, block, sectionName)

        if default then
            local value = self:addAstNode(nt.expr, field, default)
            tapd(field.child, value)
            block.fields = {field}
            if parentBlock then
                parentBlock.fields = {field}
            end
        else
            currParent = field
            tapd(block.fields, field)
            tapd(bstack, field)
        end
        if not parentBlock then
            if not block.firstField then
                block.firstField = field
            end
        end
    end


    return currParent
end

_M.parse_cmd_yield = _M.parse_cmd_section
 
function _M:parse_cmd_endsection(cmd, bstack, currParent, arglist, text)

    self:checkEndStmt(cmd, text)

    local node
    local field = bstack[#bstack]
    if #bstack < 1 or field.nodeType ~= nt.block_field then
        return self:setErr("endsection error: ")
    end

    local block = field.parent
    local sectionName = block.content
    local parentBlock = self.tpl.blocks[sectionName]
 
    if not block.appendable then
        tb.pop(block.fields)
    else
        block.fields = {field}
        parentBlock.fields = {field}
    end

    tremove(bstack)
    currParent = bstack[#bstack]

    return currParent
end

function _M:parse_cmd_append(cmd, bstack, currParent, arglist, text)

    self:checkEndStmt(cmd, text)

    local node
    local field = bstack[#bstack]
    if #bstack < 1 or field.nodeType ~= nt.block_field then
        return self:setErr("endsection error: ")
    end

    local block = field.parent
    local sectionName = block.content
    local parentBlock = self.tpl.blocks[sectionName]
 
    if not block.appendable then
        tb.pop(block.fields)

    end

    tremove(bstack)
    currParent = bstack[#bstack]

    return currParent
end

function _M:parse_cmd_show(cmd, bstack, currParent, arglist, text)

    self:checkEndStmt(cmd, text)

    local node
    local field = bstack[#bstack]
    if #bstack < 1 or field.nodeType ~= nt.block_field then
        return self:setErr("show section error: ")
    end
    
    local block = field.parent
    local sectionName = block.content
    local parentBlock = self.tpl.blocks[sectionName]

    if not block.appendable then
        tb.pop(block.fields)
    else
        block.fields = {field}
        parentBlock.fields = {field}
    end

    block.showable = true
    tremove(bstack)
    currParent = bstack[#bstack]

    return currParent
end

function _M:parse_cmd_stop(cmd, bstack, currParent, arglist, text)

    self:checkEndStmt(cmd, text)

    local node, field
    local field = bstack[#bstack]
    if #bstack < 1 or field.nodeType ~= nt.block_field then
        return self:setErr("stop section error: ")
    end

    local block = field.parent
    local sectionName = block.content
    local parentBlock = self.tpl.blocks[sectionName]

    if not block.appendable then
        tb.pop(block.fields)
    else
        block.fields = {field}
        parentBlock.fields = {field}
    end

    block.appendable = false
    parentBlock.appendable = false

    tremove(bstack)
    currParent = bstack[#bstack]
 
    return currParent
end

function _M:parse_cmd_override(cmd, bstack, currParent, arglist, text)

    self:checkEndStmt(cmd, text)

    local node, field
    local field = bstack[#bstack]
    if #bstack < 1 or field.nodeType ~= nt.block_field then
        return self:setErr("override section error: ")
    end

    local block = field.parent
    local sectionName = block.content
    local parentBlock = self.tpl.blocks[sectionName]

    block.fields = {field}
    parentBlock.fields = {field}

    tremove(bstack)
    currParent = bstack[#bstack]
 
    return currParent
end

function _M:parse_cmd_parent(cmd, bstack, currParent, arglist, text)

    local node
    local section, sectionName

    if currParent.nodeType == nt.block_field then
    else
        local lastBlock = self.tpl.lastBlock
        if not lastBlock then
            error('parent statement is only nested in section')
        end
        sectionName = lastBlock
    end

    sectionName = currParent.content
    section = self.tpl.blocks[sectionName]
    if section then
        node = self:addAstNode(nt.parent, currParent, sectionName)

        tapd(currParent.child, node)
    else

    end

    return currParent
end

function _M:parse_cmd_foreach(cmd, bstack, currParent, arglist, text)

    text = Str.trim(text, '%s')
    text = Str.trim(text, '%(')

    for range, item in sgmatch(text, "(.+)%s+as%s+([%w_]+%s*,?%s*[%w_]*)") do
        tapd(arglist, item)
        tapd(arglist, range)
    end

    local node, nodeType
    if cmd == 'foreach' then
        nodeType = nt.foreach
    elseif cmd == 'forelse' then
        nodeType = nt.forelse
    end

    node = self:addAstNode(nodeType, currParent, arglist)
    tapd(currParent.child, node)
    currParent = node
    tapd(bstack, node)

    return currParent
end

_M.parse_cmd_forelse = _M.parse_cmd_foreach

function _M:parse_cmd_endforeach(cmd, bstack, currParent, arglist, text)
    
    self:checkEndStmt(cmd, text)

    local node

    if #bstack < 1 or bstack[#bstack].nodeType ~= nt.foreach then
        return self:setErr("endforeach syntax error") 
    end
    tremove(bstack)
    currParent = bstack[#bstack]

    return currParent
end

function _M:parse_cmd_endforelse(cmd, bstack, currParent, arglist, text)
    
    self:checkEndStmt(cmd, text)

    local node

    if #bstack < 1 or bstack[#bstack].nodeType ~= nt.empty then
        return self:setErr("endforelse syntax error") 
    end
    tremove(bstack)
    currParent = bstack[#bstack]

    return currParent
end

function _M:parse_cmd_empty(cmd, bstack, currParent, arglist, text)

    self:checkEndStmt(cmd, text)

    local node, lastNodeType, node_parent

    lastNodeType = bstack[#bstack].nodeType
    if #bstack < 1 or (lastNodeType ~= nt.forelse) then
        return self:setErr("empty(forelse) syntax error ")
    end
    node_parent = currParent.parent
    node = self:addAstNode(nt.empty, node_parent, arglist)
    tapd(node_parent.child, node)
    currParent = node
    tremove(bstack)
    tapd(bstack, node)

    return currParent
end

return _M

