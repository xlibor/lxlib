
return {
    primary_keys_type = 'integer',
    normalizer = nil,
    displayer = nil,
    untag_on_delete = true,
    delete_unused_tags = false,
    tag_model = 'lxlib.ext.taggable.model.tag',
    is_tagged_label_enable = false,
    tags_table_name = 'tags',
    taggables_table_name = 'taggables'
}