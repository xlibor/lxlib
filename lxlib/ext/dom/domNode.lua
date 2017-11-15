
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        -- nodeName
        -- nodeValue
        -- nodeType
        -- parentNode
        -- childNodes
        -- firstChild
        -- lastChild
        -- previousSibling
        -- nextSibling
        -- attributes
        -- ownerDocument
        -- namespaceURI
        -- prefix
        -- localName
        -- baseURI
        -- textContent
    }
    
    return oo(this, mt)
end

function _M:ctor()

end

function _M:appendChild(newnode)

end

function _M:cloneNode(deep)

end

function _M:hasAttributes()

end

function _M:hasChildNodes()

end

function _M:insertBefore(newnode, refnode)

end

function _M:isDefaultNamespace(namespaceURI)

end

function _M:isSameNode(node)

end

function _M:isSupported(feature, version)

end

function _M:lookupNamespaceURI(prefix)

end

function _M:lookupPrefix(namespaceURI)

end

function _M:normalize()

end

function _M:removeChild(oldnode)

end

function _M:replaceChild(newnode, oldnode)

end


return _M

