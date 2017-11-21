
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'model'
}

local app, lf, tb, str, new = lx.kit()

function _M:ctor()

    self.timestamps = false
    self.fillable = {'tag_name', 'tag_slug'}
    self.table = app:conf('taggable.taggables_table_name')
    self.taggingUtil = app('tagging.util')
end

-- Morph to the tag
-- @return morphTo

function _M:taggable()

    return self:morphTo()
end

-- Get instance of tag linked to the tagged value
-- @return belongsTo

function _M:tag()

    local model = self.taggingUtil:tagModelString()
    
    return self:belongsTo(model, 'tag_slug', 'slug')
end

return _M

