
local _M = {
    _cls_    = ''    
}

local mt = {__index = _M}

local lx = require('lxlib')
local app, lf, tb, Str = lx.kit()

local concat = table.concat
local tremove = table.remove

local ssub, sgsub, sfind, smatch, sgmatch = string.sub, string.gsub, string.find, string.match, string.gmatch
local slower, supper, slen = string.lower, string.upper, string.len

local ntLookups, nodeCompilers
local nt

function _M:new(tpl)

    local this = {
        tpl = tpl,
        output = {}
    }

    setmetatable(this, mt)

    return this
end

function _M:ctor()

    if not nt then
        self:loadConfig()
    end
end

function _M:loadConfig()

    local cfg = self.tpl.config
    nt = cfg.nodeTypes

    local lookups = {}
    nodeCompilers = {}
    for k, v in pairs(nt) do
        lookups[v] = k
        nodeCompilers[k] = self['compile'..Str.ucfirst(k)]
    end

    local custom = self.tpl.custom
    local customCompilers = custom.compilers
    for k, v in pairs(customCompilers) do
        nodeCompilers[k] = v
    end

    ntLookups = lookups
end

function _M:compileNode(node)

    local nodeType = node.nodeType
    local ntName = ntLookups[nodeType]
    if ntName then
        local method = nodeCompilers[ntName]
        if method then
            method(self, node)
        else
            error('unable compile node:'..ntName)
        end
    else
        error('unknown node type:'..node.nodeType)
    end
end

function _M:compileLua(node)
     
    self:apdLineno(node)
    local str = node.content
    self:apd(str)
    self:apd('; ')
end

function _M:compileSet(node)

    local str 
    if #node.child == 0 then
        str = node.content[1] 
        str = 'local ' .. str .. '; '
        self:apd(str)
    else
        local varName = node.content[1]
        local varValue = node.child[1].content
        str = 'local ' .. varName .. ' = [=[' .. varValue .. ']=]; ';
        self:apd(str)
    end
end

function _M:compileExpr(node)
     
    self:apdLineno(node)

    local str = node.content
    local afterFilter = self:parseFilter(str)
    str = afterFilter 
    self:apd(str, nil, true, true)
end

function _M:compileNev(node)
     
    self:apdLineno(node)

    local str = node.content
    local afterFilter = self:parseFilter(str)
    str = afterFilter 
    self:apd(str, nil, true, false)
end

function _M:apdLineno(node)

    local tplIdx = node.tplIdx or 1
    tapd(self.output, "__line(" .. node.lno .. "," .. tplIdx .. ") ")
end

function _M:apd(s, isRaw, isExp, escape)

    local str = s
    if isExp then
        if escape then
            str = "e(" .. s .. ")"
        else
            str = "_tplFunc.toStr("..s..")"
        end
    end

    if not isRaw then
        if not isExp then
            tapd(self.output, str)
        else
            tapd(self.output, "tapd(___, ")
            tapd(self.output, str)
            tapd(self.output, ")\n")
        end
    else
        tapd(self.output, "tapd(___, [=[\n")
        tapd(self.output, str)
        tapd(self.output, "]=])\n")
    end
end

function _M:parseFilter(str)

    local str = sgsub(str, "([^%^])|([%w]+)[%(]+", '%1 * _tplMf:test(\'%2\',')
    str = sgsub(str, "([^%^])|([%w]+)[^%(]-", '%1 * _tplMf:test(\'%2\') ')
    str = sgsub(str, "%s+in%s+", ' * _tplMf:test(\'operator_in\') %^ ')    
    str = sgsub(str, "%^|", '|')

    return str
end

function _M:compileText(node)

    self:apdLineno(node)
    self:apd(node.content, true)

end

_M.compileRaw = _M.compileText

function _M:compileCustom(node)

    local arglist = node.content
    local custom = self.tpl.custom
    local customs = custom.customs
    local cmd, t = arglist[1], arglist[2]
    local callback = customs[cmd]

    if callback then
        self:apdLineno(node)
        t = callback(t)
        self:apd(t)
    else
        error('no custom callback for cmd:'..cmd)
    end
end

function _M:compileSwitch(block)

    local nodeType = 0
    local hasDefault = true
    local str,afterFilter
    local judgeVar 
    local hasFirstCase = false

    for _, node in ipairs(block.child) do
        nodeType = node.nodeType
        if nodeType >= nt.switch_first and nodeType <= nt.switch_default then
            if nodeType == nt.switch_first then
                self:apdLineno(node)
                self:apd("local _tplTmpSwitch =(")
                str = concat(node.content,' ')
                afterFilter = self:parseFilter(str)
                self:apd(afterFilter)
                self:apd("); " )
                self:compileChild(node.child)
            elseif nodeType == nt.switch_case then
                self:apdLineno(node)
                if hasFirstCase then 
                    self:apd("elseif _tplTmpSwitch ==(")
                else
                    self:apd("if _tplTmpSwitch ==(")
                end
                str = concat(node.content,' ')
                afterFilter = self:parseFilter(str)
                self:apd(afterFilter)
                self:apd(") then \n" )
                self:compileChild(node.child)
                hasFirstCase = true
            elseif nodeType == nt.switch_default then
                self:apdLineno(node)
                self:apd("else \n" )
                self:compileChild(node.child)
                self:apd("end \n" )
                hasDefault = false
            end
        else
            self:compileNode(node)
        end
    end

    if hasDefault then 
        self:apd("end \n" )
    end
end

function _M:compileUnless(node)

    local nodeType = 0
    local onlyIfFirst = true
    local str, afterFilter

    self:apd("if not (")
    str = concat(node.content, ' ')
    afterFilter = self:parseFilter(str)
    self:apd(afterFilter)
    self:apd(") then \n" )
    self:compileChild(node.child)

    self:apd(" end\n" )
end

function _M:compileIf(block)

    local nodeType = 0
    local onlyIfFirst = true
    local str, afterFilter

    for _, node in ipairs(block.child) do
        nodeType = node.nodeType
        if nodeType >= nt.if_first and nodeType <= nt.if_else then
            if nodeType == nt.if_first then
                self:apdLineno(node)
                self:apd("if ")
                str = concat(node.content, ' ')
                afterFilter = self:parseFilter(str)
                self:apd(afterFilter)
                self:apd(" then \n" )
                self:apdLineno(node)
                self:compileChild(node.child)
            elseif nodeType == nt.if_elseif then
                self:apdLineno(node)
                self:apd("elseif ")
                str = concat(node.content,' ')
                afterFilter = self:parseFilter(str)
                self:apd(afterFilter)
                self:apd(" then \n" )
                self:compileChild(node.child)
            elseif nodeType == nt.if_else then
                self:apdLineno(node)
                self:apd("else \n" )
                self:compileChild(node.child)
                self:apd("end\n" )
                onlyIfFirst = false
            end
        else
            self:compileNode(node)
        end
    end

    if onlyIfFirst then 
        self:apd(" end\n" )
    end
end

function _M:compileBlock(block)

    local blockName = block.content
    local isRootBlock = (blockName == '__root')
 
    if not (isRootBlock or block.showable) then return end

    if isRootBlock then
        for _, node in ipairs(block.child) do
            self:compileNode(node)
        end
    else
        if #block.fields > 0 then
            for _, field in ipairs(block.fields) do
                for _, node in ipairs(field.child) do
                    self:compileNode(node)
                end
            end
        else
            local default = block.default
            if default then
                self:compileText(default)
            end
        end
    end
end

function _M:compileParent(node)

    local blockName = node.content
    local block
    local tpl = self.tpl

    if tpl.blocks then
        block = tpl.blocks[blockName]
    end

    local field = block.firstField

    if field then
        for _, node in ipairs(field.child) do
            self:compileNode(node)
        end
    end

end

function _M:compileChild(child)

    for _, node in ipairs(child) do
        self:compileNode(node)
    end
end

function _M:compileFor(block)

    local iter_tbl = {}
    local arglist = block.content
    local kvStr, tblStr = arglist[1], arglist[2]

    if not kvStr then
        error(self.tpl.curFile)
    end
    
    local kname, vname
    
    local i, j = sfind(kvStr, ',')
    if i then
        kname = ssub(kvStr, 1, j - 1)
        vname = ssub(kvStr, j + 1)
    else
        kname = kvStr
        vname = kname
    end
    local rangeNumList = {}
    local tblStr = sgsub(tblStr, '(range)(%(.-%))', '_tplFunc.range%2')
 
    tblStr = self:parseFilter(tblStr)
    local tbl_name = tblStr
    local loopArgsCode
    local hasContinue = block.hasContinue

    local nodeIndex = block.index
    local breakFlag = 'loopNotBreak_'..nodeIndex

    if block.nodeType == nt.forelse then
        self:apdLineno(block)
        self:apd(' if not empty(' .. tbl_name .. ') then\n')
    end

    if hasContinue then
        self:apdLineno(block)
        self:apd(' local '..breakFlag..' = true\n')
    end
     
    self:apdLineno(block)
    if #rangeNumList == 0 then
        self:apd('local loop = {}; for '..kname..', '..vname..' in _tplFunc.loopIter('..tbl_name..', loop) do \n')
    else
        local rangeLow, rangeHigh, rangeStep = unpack(rangeNumList)
        if not rangeHigh then rangeHigh = 'nil' end
        if not rangeStep then rangeStep = 'nil' end
        loopArgsCode = 'local loopArgs = {low = '..rangeLow..', high = '..rangeHigh..', step = '..rangeStep..'};'
        self:apd(loopArgsCode..'local loop = {}; for '..kname..', '..vname..' in _tplFunc.loopIter({}, loop, loopArgs) do \n')
    end

    if hasContinue then
        self:apd(' while '..breakFlag..' do\n')
    end

    for _, node in ipairs(block.child) do
        self:compileNode(node)
    end

    if hasContinue then
        self:apd(' break end\n')
        self:apd(' if not '..breakFlag..' then break end\n')
    end

    self:apd("end\n")

end

_M.compileForeach = _M.compileFor
_M.compileForelse = _M.compileFor

function _M:compileExtendedTpl()

    local tplExp = self.tpl.extendsFrom

    tplExp = lf.trim(tplExp, ' "\'')
    local tpl = self.tpl
    local baseTpl = tpl:new(tpl.engine, tplExp, tpl.namespace, tpl.blocks)
    baseTpl:prepare()

    self:apd(baseTpl.strCode)

end

function _M:compileInclude(node)

    local content = node.content
    local tplName, context = content[1], content[2]

    self:apdLineno(node)
    self:apd('if 1 then \n')
    self:apd('setCurrentView("' .. tplName .. '") \n')
    if context then
        if not sfind(context, ',') then
            self:apd('  local ' .. context .. ';\n')
        else
            context = sgsub(context, ',', ';local ')
            self:apd('  local ' .. context .. ';\n')
        end
    end

    local tpl = self.tpl
    local subTpl = tpl:new(tpl.engine, tplName, tpl.namespace)
    subTpl:prepare()
 
    self:apd(subTpl.strCode)

    self:apd('setCurrentView() \nend\n')

end

function _M:compileEach(node)

    local content = node.content
    local tplName, loopTarget, eachVar, emptyTpl = unpack(content)

    local tpl = self.tpl
    local subTpl = tpl:new(tpl.engine, tplName, tpl.namespace)
    subTpl:prepare()

    self:apdLineno(node)
    self:apd('for _, ' .. eachVar .. ' in _tplFunc.myPairs(' .. loopTarget .. ') do \n')
    self:apd(subTpl.strCode)

    self:apd('end\n')

end

function _M:compileBreak(node)
 
      local args = node.content
    local t = args[1]
    t = Str.trim(t, ' ')

    local nodeLoop = node.relatedNode
    local nodeIndex = nodeLoop.index
    local breakFlag = 'loopNotBreak_'..nodeIndex
    local isWhile = (nodeLoop.nodeType == nt['while'])

    if slen(t) > 0 then
        self:apdLineno(node)
        self:apd('if ')
        local afterFilter = self:parseFilter(t)
        self:apd(afterFilter)
        self:apd(" then \n" )
        self:apdLineno(node)

        if not isWhile then
            self:apd(' '..breakFlag..' = false;')
        end
        self:apd(' break end\n')
    else
        self:apdLineno(node)
        if not isWhile then
            self:apd(' '..breakFlag..' = false;')
        end
        self:apd(' do break end\n')
    end
end

function _M:compileEmpty(node)
     
    self:apdLineno(node)
    self:apd("else \n" )
    self:compileChild(node.child)
    self:apd("end\n" )

end

function _M:compileContinue(node)
     
    local args = node.content
    local t = args[1]
    t = Str.trim(t, ' ')

    if slen(t) > 0 then
        self:apdLineno(node)
        self:apd('if ')
        local afterFilter = self:parseFilter(t)
        self:apd(afterFilter)
        self:apd(" then \n" )
        self:apdLineno(node)

        self:apd(' break end\n')
    else
        self:apdLineno(node)
        self:apd(' do break end\n')
    end
end

function _M:compileWhile(block)
     
    local args = block.content
    local t = args[1]

    self:apdLineno(block)
    self:apd('while ')
    local afterFilter = self:parseFilter(t)
    self:apd(afterFilter)
    self:apd(" do \n" )

    for _, node in ipairs(block.child) do
        self:apdLineno(node)
        self:compileNode(node)
    end

    self:apd(' end\n')

end

return _M

