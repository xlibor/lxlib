
local lx, _M, mt = oo{
    _cls_   = '',
    _ext_   = 'domNode'
}

local app, lf, tb, str = lx.kit()

local DomParser = require('lxlib.ext.dom.base.htmlparser')

function _M:ctor()

    self.baseDoc = nil
end

function _M:loadHtml(html)

    self.baseDoc = DomParser.parse(html)
end

function _M:getElementById(elementId)

    local nodes = self.baseDoc('#' .. elementId)
    if nodes then
        return nodes[1]
    end
end

function _M:getElementsByTagName(tagName)

    local nodes = self.baseDoc(tagName)

    return nodes
end

function _M:find(selectStr)

    local nodes = self.baseDoc(selectStr)

    return nodes
end

return _M

