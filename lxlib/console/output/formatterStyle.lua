
local lx, _M, mt = oo{ 
    _cls_ = ''
}

local availableForegroundColors = {
    black = {30, 39}, red = {31, 39}, green = {32, 39},
    yellow = {33, 39}, blue = {34, 39}, magenta = {35, 39},
    cyan = {36, 39}, white = {37, 39}, default = {39, 39}
}
local availableBackgroundColors = {
    black = {40, 49}, red = {41, 49}, green = {42, 49},
    yellow = {43, 49}, blue = {44, 49}, magenta = {45, 49},
    cyan = {46, 49}, white = {47, 49}, default = {49, 49}
}
local availableOptions = {
    bold = {1, 22}, underscore = {4, 24}, blink = {5, 25},
    reverse = {7, 27}, conceal = {8, 28}
}

local function tapd(t, v) t[#t + 1] = v end
local fmt = string.format
local join = lx.str.join

function _M:new()

    local this = {
        foreground = nil,
        background = nil,
        options = {}
    }

    return oo(this, mt)
end

function _M:ctor(foreground, background, options)

    if foreground then
        self:setForeground(foreground)
    end

    if background then
        self:setBackground(background)
    end

    if options then
        self:setOptions(options)
    end

end

function _M:setForeground(color)

    if not color then
        self.foreground = nil

        return
    end

    local t = availableForegroundColors[color]
    if not t then
        error('Invalid foreground color type')
    end

    self.foreground = t
end

function _M:setBackground(color)

    if not color then
        self.background = nil

        return
    end

    local t = availableBackgroundColors[color]
    if not t then
        error('Invalid background color type')
    end

    self.background = t
end

function _M:setOption(option)

    local options = self.options
    local t = availableOptions[option]

    if not t then
        error('Invalid option type')
    end

    tapd(options, t)
end

function _M:setOptions(options)

    self.options = {}
    for _, option in ipairs(options) do
        self:setOption(option)
    end
end

function _M:apply(text)

    local setCodes = {}
    local unsetCodes = {}

    if self.foreground then
        tapd(setCodes, self.foreground[1])
        tapd(unsetCodes, self.foreground[2])
    end
    if self.background then
        tapd(setCodes, self.background[1])
        tapd(unsetCodes, self.background[2])
    end
    if #self.options > 0 then
        for _, option in ipairs(self.options) do
            tapd(setCodes, option[1])
            tapd(unsetCodes, option[2])
        end
    end

    if #setCodes == 0 then
        return text
    end

    local t = fmt([[\033[%sm%s\033[%sm]],
        join(setCodes, ';'),
        text,
        join(unsetCodes, ';')
    )

    return t
end

return _M

