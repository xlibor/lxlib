
local lx, _M, mt = oo{
    _cls_   = ''
    _ext_   = 'domNode'
}

local app, lf, tb, str = lx.kit()

function _M:ctor()

    self.schemaTypeInfo = false
    self.tagName = ''
end

function _M:getAttribute(name)

end

function _M:getAttributeNode(name)

end

function _M:getAttributeNodeNS(namespaceURI, localName)

end

function _M:getElementsByTagName(name)

end

function _M:getElementsByTagNameNS(namespaceURI, localName)

end

function _M:hasAttribute(name)

end

function _M:hasAttributeNS(namespaceURI, localName)

end

function _M:removeAttribute(name)

end

function _M:removeAttributeNode(oldnode)

end

function _M:removeAttributeNS(namespaceURI, localName)

end

function _M:setAttribute(name, value)

end

function _M:setAttributeNode(attr)

end

function _M:setAttributeNodeNS(attr)

end

function _M:setAttributeNS(namespaceURI, qualifiedName, value)

end

function _M:setIdAttribute(name, isId)

end

function _M:setIdAttributeNode(attr, isId)

end

function _M:setIdAttributeNS(namespaceURI, localName, isId)

end

return _M

