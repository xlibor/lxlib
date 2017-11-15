
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'file'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        imageDefaults = {sizes = {}},
        imageRules = {sizes = 'array'}
    }
    
    return oo(this, mt)
end

-- The specific defaults for the image class.
-- @var table
-- The specific rules for the image class.
-- @var table
-- This static function is used to perform the actual upload and resizing using the Multup class.
-- @return table

function _M:doUpload()

    -- CJ: Create a folder if it doesn't already exist
    if not file_exists(self:getOption('location')) then
        mkdir(self:getOption('location'), 0777, true)
    end
    --use the multup library to perform the upload
    local result = Multup.open('file', 'image|max:' .. self:getOption('size_limit') * 1000, self:getOption('location'), self:getOption('naming') == 'random'):sizes(self:getOption('sizes')):set_length(self:getOption('length')):upload()
    
    return result[0]
end

-- Gets all rules.
-- @return table

function _M:getRules()

    local rules = parent.getRules()
    
    return tb.merge(rules, self.imageRules)
end

-- Gets all default values.
-- @return table

function _M:getDefaults()

    local defaults = parent.getDefaults()
    
    return tb.merge(defaults, self.imageDefaults)
end

return _M

