
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

function _M:copyBlock(oldBlock, newBlock)

    newBlock.fields = oldBlock.fields
    newBlock.appendable = oldBlock.appendable

end

function _M:parse_cmd_block(cmd, bstack, curParent, arglist, text)

    local t = text
    arglist[1] = t

    local block
    local sectionName = t

    local parentBlock = self.tpl.blocks[sectionName]
    if parentBlock then
        block = self:addAstNode(nt.block, curParent, sectionName)
        self:copyBlock(parentBlock, block)
    else
        block = self:addAstNode(nt.block, curParent, sectionName)
        block.appendable = true
        self.tpl.blocks[sectionName] = block
        block.showable = true
    end

    if not block.fields then
        block.fields = {}
    end

    local field

    tapd(curParent.child, block)
    field = self:addAstNode(nt.block_field, block, sectionName)
    tapd(block.fields, field)
    curParent = field
    tapd(bstack, field)
    if not parentBlock then
        if not block.firstField then
            block.firstField = field
        end
    end
 
    return curParent
end

function _M:parse_cmd_endblock(cmd, bstack, curParent, arglist, text)

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
    curParent = bstack[#bstack]

    return curParent
end

return _M
