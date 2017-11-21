
local lx, _M, mt = oo{
    _cls_       = '',
    _static_    = {}
}

local app, lf, tb, str, new = lx.kit()
local static

function _M._init_(this)

    static = this.static
end
-- Converts input into table
-- @param tagName string or table
-- @return table

function _M:makeTagArray(tagNames)

    if lf.isStr(tagNames) then
        tagNames = str.split(tagNames, ',')
    elseif not lf.isTbl(tagNames) then
        tagNames = {}
    end
    tagNames = tb.map(tagNames, str.trim)
    
    return tb.values(tagNames)
end

-- Create a web friendly URL slug from a string.
-- Although supported, transliteration is discouraged because
-- 1) most web browsers support UTF-8 characters in URLs
-- 2) transliteration causes a loss of information
-- @author Sean Murphy <sean@iamseanmurphy.com>
-- @param string str
-- @return string

function _M.s__.slug(s)

    -- Make sure string is in UTF-8 and strip invalid UTF-8 characters
    -- str = mb_convert_encoding(tostring(str), 'UTF-8')
    local options = {
        delimiter = '-',
        limit = 255,
        lowercase = true,
        replacements = {},
        transliterate = true
    }
    local char_map = {
        ['À'] = 'A',
        ['Á'] = 'A',
        ['Â'] = 'A',
        ['Ã'] = 'A',
        ['Ä'] = 'A',
        ['Å'] = 'A',
        ['Æ'] = 'AE',
        ['Ç'] = 'C',
        ['È'] = 'E',
        ['É'] = 'E',
        ['Ê'] = 'E',
        ['Ë'] = 'E',
        ['Ì'] = 'I',
        ['Í'] = 'I',
        ['Î'] = 'I',
        ['Ï'] = 'I',
        ['Ð'] = 'D',
        ['Ñ'] = 'N',
        ['Ò'] = 'O',
        ['Ó'] = 'O',
        ['Ô'] = 'O',
        ['Õ'] = 'O',
        ['Ö'] = 'O',
        ['Ő'] = 'O',
        ['Ø'] = 'O',
        ['Ù'] = 'U',
        ['Ú'] = 'U',
        ['Û'] = 'U',
        ['Ü'] = 'U',
        ['Ű'] = 'U',
        ['Ý'] = 'Y',
        ['Þ'] = 'TH',
        ['ß'] = 'ss',
        ['à'] = 'a',
        ['á'] = 'a',
        ['â'] = 'a',
        ['ã'] = 'a',
        ['ä'] = 'a',
        ['å'] = 'a',
        ['æ'] = 'ae',
        ['ç'] = 'c',
        ['è'] = 'e',
        ['é'] = 'e',
        ['ê'] = 'e',
        ['ë'] = 'e',
        ['ì'] = 'i',
        ['í'] = 'i',
        ['î'] = 'i',
        ['ï'] = 'i',
        ['ð'] = 'd',
        ['ñ'] = 'n',
        ['ò'] = 'o',
        ['ó'] = 'o',
        ['ô'] = 'o',
        ['õ'] = 'o',
        ['ö'] = 'o',
        ['ő'] = 'o',
        ['ø'] = 'o',
        ['ù'] = 'u',
        ['ú'] = 'u',
        ['û'] = 'u',
        ['ü'] = 'u',
        ['ű'] = 'u',
        ['ý'] = 'y',
        ['þ'] = 'th',
        ['ÿ'] = 'y',
        ['©'] = '(c)',
        ['Α'] = 'A',
        ['Β'] = 'B',
        ['Γ'] = 'G',
        ['Δ'] = 'D',
        ['Ε'] = 'E',
        ['Ζ'] = 'Z',
        ['Η'] = 'H',
        ['Θ'] = '8',
        ['Ι'] = 'I',
        ['Κ'] = 'K',
        ['Λ'] = 'L',
        ['Μ'] = 'M',
        ['Ν'] = 'N',
        ['Ξ'] = '3',
        ['Ο'] = 'O',
        ['Π'] = 'P',
        ['Ρ'] = 'R',
        ['Σ'] = 'S',
        ['Τ'] = 'T',
        ['Υ'] = 'Y',
        ['Φ'] = 'F',
        ['Χ'] = 'X',
        ['Ψ'] = 'PS',
        ['Ω'] = 'W',
        ['Ά'] = 'A',
        ['Έ'] = 'E',
        ['Ί'] = 'I',
        ['Ό'] = 'O',
        ['Ύ'] = 'Y',
        ['Ή'] = 'H',
        ['Ώ'] = 'W',
        ['Ϊ'] = 'I',
        ['Ϋ'] = 'Y',
        ['α'] = 'a',
        ['β'] = 'b',
        ['γ'] = 'g',
        ['δ'] = 'd',
        ['ε'] = 'e',
        ['ζ'] = 'z',
        ['η'] = 'h',
        ['θ'] = '8',
        ['ι'] = 'i',
        ['κ'] = 'k',
        ['λ'] = 'l',
        ['μ'] = 'm',
        ['ν'] = 'n',
        ['ξ'] = '3',
        ['ο'] = 'o',
        ['π'] = 'p',
        ['ρ'] = 'r',
        ['σ'] = 's',
        ['τ'] = 't',
        ['υ'] = 'y',
        ['φ'] = 'f',
        ['χ'] = 'x',
        ['ψ'] = 'ps',
        ['ω'] = 'w',
        ['ά'] = 'a',
        ['έ'] = 'e',
        ['ί'] = 'i',
        ['ό'] = 'o',
        ['ύ'] = 'y',
        ['ή'] = 'h',
        ['ώ'] = 'w',
        ['ς'] = 's',
        ['ϊ'] = 'i',
        ['ΰ'] = 'y',
        ['ϋ'] = 'y',
        ['ΐ'] = 'i',
        ['Ş'] = 'S',
        ['İ'] = 'I',
        ['Ç'] = 'C',
        ['Ü'] = 'U',
        ['Ö'] = 'O',
        ['Ğ'] = 'G',
        ['ş'] = 's',
        ['ı'] = 'i',
        ['ç'] = 'c',
        ['ü'] = 'u',
        ['ö'] = 'o',
        ['ğ'] = 'g',
        ['А'] = 'A',
        ['Б'] = 'B',
        ['В'] = 'V',
        ['Г'] = 'G',
        ['Д'] = 'D',
        ['Е'] = 'E',
        ['Ё'] = 'Yo',
        ['Ж'] = 'Zh',
        ['З'] = 'Z',
        ['И'] = 'I',
        ['Й'] = 'J',
        ['К'] = 'K',
        ['Л'] = 'L',
        ['М'] = 'M',
        ['Н'] = 'N',
        ['О'] = 'O',
        ['П'] = 'P',
        ['Р'] = 'R',
        ['С'] = 'S',
        ['Т'] = 'T',
        ['У'] = 'U',
        ['Ф'] = 'F',
        ['Х'] = 'H',
        ['Ц'] = 'C',
        ['Ч'] = 'Ch',
        ['Ш'] = 'Sh',
        ['Щ'] = 'Sh',
        ['Ъ'] = '',
        ['Ы'] = 'Y',
        ['Ь'] = '',
        ['Э'] = 'E',
        ['Ю'] = 'Yu',
        ['Я'] = 'Ya',
        ['а'] = 'a',
        ['б'] = 'b',
        ['в'] = 'v',
        ['г'] = 'g',
        ['д'] = 'd',
        ['е'] = 'e',
        ['ё'] = 'yo',
        ['ж'] = 'zh',
        ['з'] = 'z',
        ['и'] = 'i',
        ['й'] = 'j',
        ['к'] = 'k',
        ['л'] = 'l',
        ['м'] = 'm',
        ['н'] = 'n',
        ['о'] = 'o',
        ['п'] = 'p',
        ['р'] = 'r',
        ['с'] = 's',
        ['т'] = 't',
        ['у'] = 'u',
        ['ф'] = 'f',
        ['х'] = 'h',
        ['ц'] = 'c',
        ['ч'] = 'ch',
        ['ш'] = 'sh',
        ['щ'] = 'sh',
        ['ъ'] = '',
        ['ы'] = 'y',
        ['ь'] = '',
        ['э'] = 'e',
        ['ю'] = 'yu',
        ['я'] = 'ya',
        ['Є'] = 'Ye',
        ['І'] = 'I',
        ['Ї'] = 'Yi',
        ['Ґ'] = 'G',
        ['є'] = 'ye',
        ['і'] = 'i',
        ['ї'] = 'yi',
        ['ґ'] = 'g',
        ['Č'] = 'C',
        ['Ď'] = 'D',
        ['Ě'] = 'E',
        ['Ň'] = 'N',
        ['Ř'] = 'R',
        ['Š'] = 'S',
        ['Ť'] = 'T',
        ['Ů'] = 'U',
        ['Ž'] = 'Z',
        ['č'] = 'c',
        ['ď'] = 'd',
        ['ě'] = 'e',
        ['ň'] = 'n',
        ['ř'] = 'r',
        ['š'] = 's',
        ['ť'] = 't',
        ['ů'] = 'u',
        ['ž'] = 'z',
        ['Ą'] = 'A',
        ['Ć'] = 'C',
        ['Ę'] = 'e',
        ['Ł'] = 'L',
        ['Ń'] = 'N',
        ['Ó'] = 'o',
        ['Ś'] = 'S',
        ['Ź'] = 'Z',
        ['Ż'] = 'Z',
        ['ą'] = 'a',
        ['ć'] = 'c',
        ['ę'] = 'e',
        ['ł'] = 'l',
        ['ń'] = 'n',
        ['ó'] = 'o',
        ['ś'] = 's',
        ['ź'] = 'z',
        ['ż'] = 'z',
        ['Ā'] = 'A',
        ['Č'] = 'C',
        ['Ē'] = 'E',
        ['Ģ'] = 'G',
        ['Ī'] = 'i',
        ['Ķ'] = 'k',
        ['Ļ'] = 'L',
        ['Ņ'] = 'N',
        ['Š'] = 'S',
        ['Ū'] = 'u',
        ['Ž'] = 'Z',
        ['ā'] = 'a',
        ['č'] = 'c',
        ['ē'] = 'e',
        ['ģ'] = 'g',
        ['ī'] = 'i',
        ['ķ'] = 'k',
        ['ļ'] = 'l',
        ['ņ'] = 'n',
        ['š'] = 's',
        ['ū'] = 'u',
        ['ž'] = 'z',
        ['Ă'] = 'A',
        ['ă'] = 'a',
        ['Ș'] = 'S',
        ['ș'] = 's',
        ['Ț'] = 'T',
        ['ț'] = 't'
    }
    -- Make custom replacements
    s = str.rereplace(s, tb.keys(options.replacements), options.replacements)
    -- Transliterate characters to ASCII
    if options.transliterate then
        s = str.replace(s, tb.keys(char_map), char_map)
    end
    -- Replace non-alphanumeric characters with our delimiter
    s = str.rereplace(s, '[^\\p{L}\\p{Nd}]+', options.delimiter, 'ijou')
    -- Remove duplicate delimiters
    s = str.rereplace(s, '(' .. str.pregQuote(options.delimiter, '/') .. '){2,}', '$1')
    -- Truncate slug to max. characters
    s = str.substr(s, 1, options.limit or str.len(s))
    -- Remove delimiter from ends
    s = str.trim(s, options.delimiter)
    -- Normalizer tag name
    s = static.tagName(s)
    -- s = app():make(Pinyin.class):permlink(s)
    
    return options.lowercase and str.lower(s) or s
end

function _M.s__.tagName(string)

    -- from http://stackoverflow.com/a/8483919/689832
    string = str.replace(string, ' ', '-')
    -- Replaces all spaces with hyphens.
    
    return str.rereplace(string, "[^\\p{L}\\p{N}]", '-', 'ijou')
    -- Removes special chars.
end

-- Private! Please do not call this function directly, just let the Tag library use it.
-- Increment count of tag by one. This function will create tag record if it does not exist.
-- @param Tag Object tag

function _M:incrementCount(tag, count)

    if count <= 0 then
        
        return
    end
    tag.count = tag.count + count
    tag:save()
end

-- Private! Please do not call this function directly, let the Tag library use it.
-- Decrement count of tag by one. This function will create tag record if it does not exist.
-- @param Tag Object tag

function _M:decrementCount(tag, count)

    local model
    if count <= 0 then
        
        return
    end
    tag.count = tag.count - count
    if tag.count < 0 then
        tag.count = 0
        model = self:tagModelString()
        app('logger'):warning("The " .. model .. " count for `" .. tag.name .. "` was a negative number. This probably means your data got corrupted. Please assess your code and report an issue if you find one.")
    end
    tag:save()
end

-- Look at the tags table and delete any tags that are no londer in use by any taggable database rows.
-- Does not delete tags where 'suggest' is true
-- @return int

function _M:deleteUnusedTags()

    local model = self:tagModelString()
    
    return model.deleteUnused()
end

-- @return string

function _M:tagModelString()

    return app:conf('taggable.tag_model', 'lxlib.ext.tagging.model.tag')
end

-- Check DB Slug Dulplication
function _M:uniqueSlug(slug_str, tag_name)

    local model = self:tagModelString()

    local tag = new(model):where('slug', slug_str):first()
    if not lf.isEmpty(slug_str) and (tag) then
        -- 只有当 slug 一样但 tagname 不一样的情况下，才自动设置随机 slug 后缀
        if tag.name ~= self:normalizeTagName(tag_name) then
            slug_str = slug_str .. '-' .. lf.rand(1000, 9999)
        end
    end
    
    return slug_str
end

-- Should be call before insert into database
function _M:normalizeAndUniqueSlug(tag_name)

    local normalizer = app:conf('taggable.normalizer') or static.slug
    -- Normalize
    local slug_string = lf.call(normalizer, tag_name)
    -- Make sure slug is unique
    
    return self:uniqueSlug(slug_string, tag_name)
end

-- Should be call before insert into database
function _M:normalizeTagName(string)

    string = str.title(string)
    local normalizer = app:conf('taggable.displayer') or static.tagName
    -- Normalize
    
    return lf.call(normalizer, string)
end

return _M

