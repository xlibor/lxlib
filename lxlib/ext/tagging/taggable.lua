
local lx, _M = oo{
    _cls_       = '',
    _static_    = {}
}

local app, lf, tb, str, new = lx.kit()
local Tagged = lx.use('tagging.tagged')
local static

function _M._init_(this)

    static = this.static
    static.taggingUtil = app('tagging.util')
end

function _M:ctor()

    self:rawset('autoTagTmp', false)
    self:rawset('autoTagSet', false)
end

function _M.s__.bootTaggable()

    if static.untagOnDelete() then
        static.deleting(function(model)
            model:untag()
        end)
    end
    static.saved(function(model)
        model:autoTagPostSave()
    end)
    static.taggingUtil = app(TaggingUtil)
end

-- Return collection of tagged rows related to the tagged model
-- @return model.col

function _M:tagged()

    return self:morphMany('lxlib.ext.tagging.model.tagged', 'taggable'):with('tag')
end

function _M:tags()

    return self:morphToMany(static.taggingUtil:tagModelString(), 'taggable')
end

-- Set the tag names via attribute, example model.tag_names = 'foo, bar';
-- @param string value

function _M:getTagNamesAttribute(value)

    return str.join(self:tagNames(), ', ')
end

-- Perform the action of tagging the model with the given string
-- @param tagName string or table

function _M:tag(...)

    local tagNames = lf.needArgs(...)

    tagNames = static.taggingUtil:makeTagArray(tagNames)

    for _, tagName in ipairs(tagNames) do
        self:addTag(tagName)
    end
end

-- Return table of the tag names related to the current model
-- @return table

function _M:tagNames()

    return self:tags():pluck('name')
end

-- Return table of the tag slugs related to the current model
-- @return table

function _M:tagSlugs()

    return self:tags():pluck('slug')
end

-- Remove the tag from this model
-- @param tagName string or table (or null to remove all tags)

function _M:untag(tagNames)

    if not tagNames then
        tagNames = self:tagNames()
    end
    tagNames = static.taggingUtil:makeTagArray(tagNames)
    for _, tagName in ipairs(tagNames) do
        self:removeTag(tagName)
    end
    if static.shouldDeleteUnused() then
        static.taggingUtil:deleteUnusedTags()
    end
end

-- Replace the tags from this model
-- @param tagName string or table

function _M:retag(...)
    
    local tagNames = lf.needArgs(...)
    tagNames = static.taggingUtil:makeTagArray(tagNames)
    local currentTagNames = self:tagNames()
    local deletions = tb.diff(currentTagNames, tagNames)
    local additions = tb.diff(tagNames, currentTagNames)
    self:untag(deletions)
    for _, tagName in ipairs(additions) do
        self:addTag(tagName)
    end
end

-- Filter model to subset with the given tags
-- @param tagNames table|string

function _M:scopeWithAllTags(query, ...)

    local ids
    local tagNames = lf.needArgs(...)
    tagNames = static.taggingUtil:makeTagArray(tagNames)
    local model = static.taggingUtil:tagModelString()
    local tagids = model.byTagNames(tagNames):pluck('id')
    local className = query:getModel():getMorphClass()
    local primaryKey = self:getKeyName()
    local tagid_count = #tagids
    if tagid_count > 0 then
        ids = Tagged.where('taggable_type', className)
            :whereIn('tag_id', tagids)
            :whereRaw('`tag_id` in (' .. str.join(tagids, ',') .. ') group by taggable_id having count(taggable_id) =' .. tagid_count)
            :pluck('taggable_id')

        query:whereIn(self:getTable() .. '.' .. primaryKey, ids)
    end
    
    return query
end

-- Filter model to subset with the given tags
-- @param tagNames table|string

function _M:scopeWithAnyTag(query, ...)

    local tagNames = lf.needArgs(...)

    tagNames = static.taggingUtil:makeTagArray(tagNames)
    local model = static.taggingUtil:tagModelString()
    local tagids = new(model):byTagNames(tagNames):pluck('id')
    local className = query:getModel():getMorphClass()
    local primaryKey = self:getKeyName()
    local tags = Tagged.whereIn('tag_id', tagids)
        :where('taggable_type', className)
        :pluck('taggable_id')
    
    return query:whereIn(self:getTable() .. '.' .. primaryKey, tags)
end

-- Adds a single tag
-- @param tagName string

function _M.__:addTag(tagName)

    local count
    local model = static.taggingUtil:tagModelString()

    local tag = new(model):byTagName(tagName):first()
    if tag then
        -- If tag is exists, do not create
        count = self:tagged():where('tag_id', '=', tag.id):take(1):count()
        if count >= 1 then
            return
        else
            self:tags():attach(tag.id)
            tag:increment('count', tag:getAttr('count') + 1)
        end
    else
        -- If tag is not exists, create tag and attach to object
        tag = new(model)
        tag.name = tagName
        tag:setAttr('count', 1)
        tag:save()
        self:tags():attach(tag.id)
    end
    if app:conf('taggable.is_tagged_label_enable') and self.is_tagged ~= 'yes' then
        self.is_tagged = 'yes'
        self:save()
    end
    self.relations.tagged = nil

    app:fire('tagAdded', self)
end

-- Removes a single tag
-- @param tagName string

function _M.__:removeTag(tagName)

    local tag = self:tags():byTagName(tagName):first()
    if tag then
        self:tags():detach(tag.id)
        static.taggingUtil:decrementCount(tag, 1)
    end
    if app:conf('taggable.is_tagged_label_enable')
        and self.is_tagged ~= 'no'
        and self:tags():count() <= 0 then

        self.is_tagged = 'no'
        self:save()
    end
    self.relations.tagged = nil
    app:fire('tagRemoved', self)
end

-- Return an table of all of the tags that are in use by this model
-- @return col

function _M.t__.existingTags(this)

    local tags_table_name = app:conf('taggable.tags_table_name')
    
    local q = Tagged.distinct()
    q:join(tags_table_name):on('tag_id', '=', tags_table_name .. '.id')
    q:where('taggable_type', '=', new(this):getMorphClass())
    :orderBy('tag_id', 'ASC')

    return q:get(
        {tags_table_name .. '.slug','slug'},
        {tags_table_name .. '.name','name'},
        {tags_table_name .. '.count','count'}
    )
end

-- Should untag on delete

function _M.s__.untagOnDelete()

    return static.untagOnDelete and static.untagOnDelete or app:conf('taggable.untag_on_delete')
end

-- Delete tags that are not used anymore

function _M.s__.shouldDeleteUnused()

    return app:conf('taggable.delete_unused_tags')
end

-- Set tag names to be set on save
-- @param mixed value Data for retag
-- @access public

function _M:setTagNamesAttribute(value)

    self.autoTagTmp = value
    self.autoTagSet = true
end

-- AutoTag post-save hook
-- Tags model based on data stored in tmp property, or untags if manually
-- set to falsey value

function _M:autoTagPostSave()

    if self.autoTagSet then
        if self.autoTagTmp then
            self:retag(self.autoTagTmp)
        else 
            self:untag()
        end
    end
end

-- Sync tags with tag_id table
-- @param tag_ids table|null

function _M:tagWithTagIds(tag_ids)

    tag_ids = tag_ids or {}
    if #tag_ids <= 0 then
        
        return
    end
    local model = static.taggingUtil:tagModelString()
    local tag_names = model.byTagIds(tag_ids):pluck('name')
    self:retag(tag_names)
end

return _M

