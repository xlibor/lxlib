
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str, new = lx.kit()
local slen, ssub = string.len, string.sub
local tconcat = table.concat

function _M:new(baseNode)

    local this = {
        baseNode = baseNode,
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

function _M.d__:textContent()

    return self.baseNode:textonly()
end

function _M.d__:parentNode()

    return self:newNode(self.baseNode.parent)
end

function _M.d__:nodeName()

    return self.baseNode.name
end

function _M.d__:childNodes()

    return self:initNodes(self.baseNode.nodes)
end

function _M.d__:level()

    return self.baseNode.level
end

function _M:getText()

    return self.baseNode:gettext()
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

function _M:getElementById(elementId)

    local nodes = self.baseNode('#' .. elementId)
    local baseNode = nodes[1]

    if baseNode then
        return new('domElement', baseNode)
    end
end

function _M:getElementsByTagName(name)

    local nodes = self.baseNode:select(name)
    if #nodes > 0 then
 
        return self:initNodes(nodes)
    else
        return {}
    end
end

function _M:getElementsByTagNameNS(namespaceURI, localName)

end

function _M:find(selectStr)

    local nodes = self.baseNode(selectStr)
    nodes = self:initNodes(nodes) or {}

    return nodes
end

function _M:first(selectStr)

    local nodes = self:find(selectStr)
    if nodes and #nodes > 0 then
        return nodes[1]
    end
end

function _M:last(selectStr)

    local nodes = self:find(selectStr)
    if nodes and #nodes > 0 then
        return nodes[#nodes]
    end
end

function _M.__:initNodes(baseNodes)

    local nodes = {}
    for i, node in ipairs(baseNodes) do
        tapd(nodes, new('domElement', node))
    end

    return nodes
end

function _M:removedBy(nodes) 

    if type(nodes) == 'string' then
        nodes = self:find(nodes)
    end

    local root = self.baseNode.root
    local rootText = root._text

    local ranges = {}

    local node, openstart, closeend

    if #nodes == 0 and next(nodes) then
        node = nodes.baseNode
        openstart, closeend = node._openstart, node._closeend
        rootText = ssub(rootText, 1, openstart - 1) .. ssub(rootText, closeend + 1)
    elseif #nodes > 0 then
        local strList = {}
        for i = 1, str.len(rootText) do
            local inRange = false
            for _, node in ipairs(nodes) do
                node = node.baseNode
                openstart, closeend = node._openstart, node._closeend
                if i >= openstart and i <= closeend then
                    inRange = true
                    break
                end
            end
            if not inRange then
                tapd(strList, ssub(rootText, i, i))
            end
        end
        rootText = tconcat(strList)
    else

    end

    local newNode = new('domDocument'):loadHtml(rootText)

    return newNode
end


function _M.__:newNode(baseNode)

    return new('domElement', baseNode)
end

function _M:_get_(key)

    return self:getAttribute(key)
end

return _M

