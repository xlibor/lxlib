
local lx, _M = oo{ 
    _cls_    = '',
    _ext_     = 'viewException'
}

local app, lf, tb, Str = lx.kit()
local split = Str.split
local smatch = string.match

local util = require('lxlib.view.engine.base.util')

function _M:ctor(tpl, pre)
    
    self.pre = pre
    local view = tpl.view
    self.view = view
    local strCode = tpl.strCode
    local tErr = pre.msg

    local errline = smatch(tErr, "%]:(%d+):")
    errline = tonumber(errline)
    local strList = split(strCode, "\n")
    local errPos = strList[errline]

    local lineIn, tplIdx = smatch(errPos, "line%((%d+),(%d+)%)")
    if lineIn then lineIn = tonumber(lineIn) end
    if tplIdx then tplIdx = tonumber(tplIdx) end

    local lineContent = ''

    if lineIn then
        local tpls = tpl.tpls
        if not tpls then
            lineContent = tpl.srclines[lineIn]
        else
            local curTpl = tpls[tplIdx]
            lineContent = curTpl.srclines[lineIn]
            view = curTpl.view
        end
        errPos = lineIn
    end

    local detail = smatch(tErr, "%]:%d+:(.*)[\n]?") or 'unknown'
    lineContent = util.escape(lineContent)
    self.msg = 'lua syntax error in "'..view ..'",line:' .. errPos ..',str:'..lineContent..', detail:' .. detail
end

return _M

