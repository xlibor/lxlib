
local lx, _M, mt = oo{
    _cls_       = '',
    _ext_       = 'model',
    _static_    = {}
}

local app, lf, tb, str, new = lx.kit()
local static

function _M._init_(this)

    static = this.static
end

function _M:ctor()

    self.fillable = {'name'}
    self.table = app:conf('taggable.tags_table_name')
    local connection = app:conf('taggable.connection')
    if connection then
        self.connection = connection
    end
    self.taggingUtil = app('tagging.util')
end

function _M:isUserUpdateSlug(options)

    -- If slug in dirty, it mean user manual setting `tag.slug = 'foo'`
    if tb.exists(self:getDirty(), 'slug') then
        
        return true
    end
    -- If slug in options table, it mean user use `tag:save({slug = 'foo'})` to update slug
    if tb.exists(options, 'slug') then
        
        return true
    end
    
    return false
end

function _M:save(options)

    options = options or {}
    local validator = app('validator'):make(
        {name = self.name}, {name = 'required|min:1'})
    if validator:passes() then
        if not self:isUserUpdateSlug(options) then
            -- If user has been set slug，it do not need set slug by automatically
            self.slug = self.taggingUtil:normalizeAndUniqueSlug(self.name)
        end
        -- this->name = this->taggingUtil->normalizeTagName($this->name);
        
        return self:__super(_M, 'save', options)
    else 
        throw('exception', 'Tag Name is required')
    end
end

-- Get suggested tags

function _M:scopeSuggested(query)

    return query:where('suggest', true)
end

-- Set the name of the tag : tag.name = 'myname'
-- @param string value

function _M:setNameAttribute(value)

    self.attrs.name = self.taggingUtil:normalizeTagName(value)
end

-- Look at the tags table and delete any tags that are no londer in use by any taggable database rows.
-- Does not delete tags where 'suggest'value is true
-- @return int

function _M.t__.deleteUnused(this)

    return new(this):newQuery():where('count', '=', 0):where('suggest', false):delete()
end

-- Get one Tag item by tag name
function _M:scopeByTagName(query, tag_name)

    -- mormalize string
    tag_name = self.taggingUtil:normalizeTagName(str.trim(tag_name))
    
    return query:where('name', tag_name)
end

function _M:scopeByTagSlug(query, tag_slug)

    return query:where('slug', tag_slug)
end

-- Get Tag collection by tag name table
function _M:scopeByTagNames(query, tag_names)

    local normalize_tag_names = {}
    for _, tag_name in ipairs(tag_names) do
        -- mormalize string
        tapd(normalize_tag_names, self.taggingUtil:normalizeTagName(str.trim(tag_name)))
    end
    
    return query:whereIn('name', normalize_tag_names)
end

-- Get Tag collection by tag id table
function _M:scopeByTagIds(query, tag_ids)

    return query:whereIn('id', tag_ids)
end

-- Get tag ids tag name table
function _M:scopeIdsByNames(query, tagNames)

    return query:whereIn('name', tagNames):pluck('id')
end

return _M

