
local lx, _M = oo{ 
    _cls_    = '',
    _ext_     = 'viewException'
}

local split = lx.str.split
local smatch = string.match

local util = require('lxlib.view.engine.base.util')

function _M:ctor(tpl, pre)
    
    self.pre = pre
    local view = tpl.view
    self.view = view
    local strCode = tpl.strCode
    local tErr, tTrace = pre.msg, pre.trace
     
    local errline, detail = smatch(tErr, "%]:(%d+):(.*)[\n]?")
    errline = tonumber(errline)
    if not errline then
        errline = smatch(tTrace, "%]:(%d+):")
        errline = tonumber(errline)
        detail = smatch(tErr, ":%d+:(.*)[\n]?") or tErr
    end
    local strList = split(strCode, "\n")

    local errPos = strList[errline]

    if not errPos then
        self.msg = 'render error in file "' .. view
            .. '",line:unknown'
            .. ',<br>detail:' .. tErr

        return 
    end

    local lineIn, tplIdx, otherCode = smatch(errPos, "line%((%d+),(%d+)%)(.*)")
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

    lineContent = util.escape(lineContent)
    local msg = 'render error in file "' .. view
        .. '",line:' .. errPos
        .. ',<br>str:' .. lineContent 
        .. ',<br>detail:' .. detail
    if otherCode then
        msg = msg .. ',<br>code:' .. otherCode
    end
    
    self.msg = msg
end

return _M

