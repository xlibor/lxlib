
local lx, _M, mt = oo{ 
    _cls_ = ''
}

local app, lf, tb, str, new = lx.kit()

local function tapd(t, v) t[#t + 1] = v end

function _M:new()

    local this = {
        styles = {}
    }

    return oo(this, mt)
end

function _M:ctor(styles)

    self:init()

    if styles then
        for name , style in pairs(styles) do
            self:setStyle(name, style)
        end
    end
end

function _M:init()
    
    self:setStyle('text', new('outputFormatterStyle', 'default', 'default'))
    self:setStyle('error', new('outputFormatterStyle', 'white', 'red'))
    self:setStyle('info', new('outputFormatterStyle', 'green', 'default'))
    self:setStyle('comment', new('outputFormatterStyle', 'yellow'))
    self:setStyle('question', new('outputFormatterStyle', 'black', 'cyan'))
    self:setStyle('warn', new('outputFormatterStyle', 'red'))
    self:setStyle('cheer', new('outputFormatterStyle', 'black', 'green'))
end

function _M:setStyle(name, style)

    self.styles[name] = style
end

function _M:getStyle(name)

    return self.styles[name]
end

function _M:format(msg)
     
    local text = msg.text

    local msgs = self:parseMsg(text)

    if not msgs then
        return self:formatMsg(msg)
    else
        local ret = {}
        for _, msg in ipairs(msgs) do

            tapd(ret, self:formatMsg(msg))
        end

        return str.join(ret)
    end
end

function _M:formatMsg(msg)

    local text = msg.text
    local styleName = msg.style or 'text'

    local style = self:getStyle(styleName)

    return style:apply(text)
end

function _M:parseMsg(msg)
 
    local it, err = ngx.re.gmatch(msg, 
        [[<(\w+)[^>]*?(>(.*?)</(\w+)>)|(/>)]]
    )

    if not it then
        return 
    end
 
    local ret = {}

    while true do
        local m, err = it()
        if err then break end
        if not m then break end

        local tag1, text, tag2 = m[1], m[3], m[4]

        if tag1 == tag2 then
            tapd(ret, {text = text, style = tag1})
        end
    end

    if #ret == 0 then ret = nil end

    return ret
end

return _M

