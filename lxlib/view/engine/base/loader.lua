
local _M = {
    _cls_ = ''
}
local mt = { __index = _M }

local lx = require('lxlib')
local app, lf, tb, Str = lx.kit()

local tconcat = table.concat
local ssub, sfind, slen = string.sub, string.find, string.len
local split = Str.split

function _M:new(tpl)

    local this = {
        tpl = tpl
    }

    setmetatable(this, mt)

    return this
end

function _M:load()
     
    local fileName = self.tpl.view

    local isPlain
    if sfind(fileName, '%s') then
        isPlain = true
    else
        isPlain = false
    end

    if not isPlain then

        fileName = self:findPath(fileName, self.tpl.namespace)
    end

    local srclines = {}
    if not isPlain then
        local f, err = io.open(fileName, 'r')
        self.tpl.curFile = fileName
        if f then
            for line in f:lines() do
                tapd(srclines, line .. "\n")
            end
            f:close()
        else
            lx.throw('viewNotExistsException', fileName, err)
        end
    else
        self.tpl.curFile = 'plain'
        local lines = split(fileName, "\n")
        for _, line in ipairs(lines) do
            tapd(srclines, line .. "\n")
        end
    end

    if not srclines then
        lx.throw('viewNotExistsException', fileName)
    end

    self.tpl.srclines = srclines
end

function _M:findPath(view, namespace)

    local finder = app.view.finder

    return finder:find(view, namespace)
end

return _M

