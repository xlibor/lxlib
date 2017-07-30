
local lx, _M, mt = oo{
    _cls_       = ''
}

local app, lf, tb, str = lx.kit()
local fs = lx.fs

function _M:new()

    local this = {

    }

    return oo(this, mt)
end

function _M:load()

    local files = fs.files(self:getTestPath(), 'n', function(file)

        local name, ext = file:sub(1, -5), file:sub(-3)

        if ext == 'lua' then
            if str.endsWith(name, 'Test') then
                return '.test.' .. name
            end
        end
    end)

    return files
end

function _M:getTestPath()

    return lx.dir('test')
end

return _M

