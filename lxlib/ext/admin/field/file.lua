
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'field'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        defaults = {
        naming = 'random',
        length = 32,
        mimes = false,
        size_limit = 2,
        display_raw_value = false
    },
        rules = {
        location = 'required|string|directory',
        naming = 'in:keep,random',
        length = 'integer|min:0',
        mimes = 'string'
    }
    }
    
    return oo(this, mt)
end

-- The specific defaults for subclasses to override
-- @var table
-- The specific rules for subclasses to override
-- @var table
-- Builds a few basic options

function _M:build()

    parent.build()
    --set the upload url depending on the type of config this is
    local url = self.validator:getUrlInstance()
    local route = self.config:getType() == 'settings' and 'admin_settings_file_upload' or 'admin_file_upload'
    --set the upload url to the proper route
    self.suppliedOptions['upload_url'] = url:route(route, {self.config:getOption('name'), self.suppliedOptions['field_name']})
end

-- This static function is used to perform the actual upload and resizing using the Multup class
-- @return table

function _M:doUpload()

    local mimes = self:getOption('mimes') and '|mimes:' .. self:getOption('mimes') or ''
    --use the multup library to perform the upload
    local result = Multup.open('file', 'max:' .. self:getOption('size_limit') * 1000 .. mimes, self:getOption('location'), self:getOption('naming') == 'random'):set_length(self:getOption('length')):upload()
    
    return result[0]
end

return _M

