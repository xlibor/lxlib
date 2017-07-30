
local lx, _M, mt = oo{
    _cls_     = '',
    _bond_     = 'htmlable'
}

function _M:ctor(html)

    self.html = html or 'fake'
end

function _M:toHtml()

    return self.html
end

function _M:toStr()

    return self.html
end

return _M

