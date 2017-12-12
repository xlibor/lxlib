
local lx, _M, mt = oo{
    _cls_   = '',
    _ext_   = 'domNode'
}

local app, lf, tb, str, new = lx.kit()

local DomParser = require('lxlib.dom.base.htmlparser')

function _M:ctor()

    self.baseNode = nil
end

function _M:loadHtml(html, limit)

    limit = limit or 3000
    self.baseNode = DomParser.parse(html, limit)

    return self
end

function _M:loadXml(xml)

    self.baseNode = DomParser.parse(xml)
end

function _M:save()

end

function _M:createAttribute(name)

end

function _M:createAttributeNS(namespaceURI, qualifiedName)

end

function _M:createElement(name, value)

end

function _M:createElementNS(namespaceURI, qualifiedName, value)

end

function _M:createTextNode(content)

end

function _M:createElement(name, value)

end

function _M:createElement(name, value)

end

return _M

