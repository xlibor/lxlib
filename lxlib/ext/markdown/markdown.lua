
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str, new = lx.kit()

local Md = require('discount')

function _M:new()

    local this = {

    }

    return oo(this, mt)
end

function _M:md2html(mdStr, options)

    local html
    local doc, err

    mdStr = str.rereplace(mdStr, '>```', '>\n```')
    mdStr = str.rereplace(mdStr, '([^\n]+\n)```', '$1\n```')

    if options then
        doc, err = Md.compile(mdStr, unpack(options))
    else
        doc, err = Md.compile(mdStr, 'toc', 'fencedcode', 'nohtml')
    end

    if doc then 
        html = doc.body
    else
        error(err)
    end

    return html
end

function _M:html2md(html, options)

end

return _M

