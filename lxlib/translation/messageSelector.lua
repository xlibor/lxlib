
local lx, _M, mt = oo{
    _cls_ = ' MessageSelector'
}

local app, lf, tb, str = lx.kit()

function _M:choose(line, number, locale)

    local segments = str.split(line, '|')
    local value = self:extract(segments, number)
    if (value) ~= nil then
        
        return str.trim(value)
    end
    segments = self:stripConditions(segments)
    local pluralIndex = self:getPluralIndex(locale, number)
    if #segments == 1 or not segments[pluralIndex] then
        
        return segments[0]
    end
    
    return segments[pluralIndex]
end

function _M.__:extract(segments, number)

    local line
    for _, part in pairs(segments) do
        line = self:extractFromString(part, number)
        if line then
            
            return line
        end
    end
end

function _M.__:extractFromString(part, number)

    str.rematch(part, '/^[\\{\\[]([^\\[\\]\\{\\}]*)[\\}\\]](.*)/s', matches)
    if #matches ~= 3 then
        
        return
    end
    local condition = matches[1]
    local value = matches[2]
    if str.contains(condition, ',') then
        local from, to = str.div(condition, ',')
        if to == '*' and number >= from then
            
            return value
        elseif from == '*' and number <= to then
            
            return value
        elseif number >= from and number <= to then
            
            return value
        end
    end
    
    return condition == number and value or nil
end

function _M.__:stripConditions(segments)

    return collect(segments):map(function(part)
        
        return str.rereplace(part, '/^[\\{\\[]([^\\[\\]\\{\\}]*)[\\}\\]]/', '')
    end):all()
end

function _M:getPluralIndex(locale, number)

    local st = locale
    if st == 'az' then
    elseif st == 'bo' then
    elseif st == 'dz' then
    elseif st == 'id' then
    elseif st == 'ja' then
    elseif st == 'jv' then
    elseif st == 'ka' then
    elseif st == 'km' then
    elseif st == 'kn' then
    elseif st == 'ko' then
    elseif st == 'ms' then
    elseif st == 'th' then
    elseif st == 'tr' then
    elseif st == 'vi' then
    elseif st == 'zh' then
        
        return 0
    elseif st == 'af' then
    elseif st == 'bn' then
    elseif st == 'bg' then
    elseif st == 'ca' then
    elseif st == 'da' then
    elseif st == 'de' then
    elseif st == 'el' then
    elseif st == 'en' then
    elseif st == 'eo' then
    elseif st == 'es' then
    elseif st == 'et' then
    elseif st == 'eu' then
    elseif st == 'fa' then
    elseif st == 'fi' then
    elseif st == 'fo' then
    elseif st == 'fur' then
    elseif st == 'fy' then
    elseif st == 'gl' then
    elseif st == 'gu' then
    elseif st == 'ha' then
    elseif st == 'he' then
    elseif st == 'hu' then
    elseif st == 'is' then
    elseif st == 'it' then
    elseif st == 'ku' then
    elseif st == 'lb' then
    elseif st == 'ml' then
    elseif st == 'mn' then
    elseif st == 'mr' then
    elseif st == 'nah' then
    elseif st == 'nb' then
    elseif st == 'ne' then
    elseif st == 'nl' then
    elseif st == 'nn' then
    elseif st == 'no' then
    elseif st == 'om' then
    elseif st == 'or' then
    elseif st == 'pa' then
    elseif st == 'pap' then
    elseif st == 'ps' then
    elseif st == 'pt' then
    elseif st == 'so' then
    elseif st == 'sq' then
    elseif st == 'sv' then
    elseif st == 'sw' then
    elseif st == 'ta' then
    elseif st == 'te' then
    elseif st == 'tk' then
    elseif st == 'ur' then
    elseif st == 'zu' then
        
        return number == 1 and 0 or 1
    elseif st == 'am' then
    elseif st == 'bh' then
    elseif st == 'fil' then
    elseif st == 'fr' then
    elseif st == 'gun' then
    elseif st == 'hi' then
    elseif st == 'hy' then
    elseif st == 'ln' then
    elseif st == 'mg' then
    elseif st == 'nso' then
    elseif st == 'xbr' then
    elseif st == 'ti' then
    elseif st == 'wa' then
        
        return number == 0 or number == 1 and 0 or 1
    elseif st == 'be' then
    elseif st == 'bs' then
    elseif st == 'hr' then
    elseif st == 'ru' then
    elseif st == 'sr' then
    elseif st == 'uk' then
        
        return number % 10 == 1 and number % 100 ~= 11 and 0 or (number % 10 >= 2 and number % 10 <= 4 and (number % 100 < 10 or number % 100 >= 20) and 1 or 2)
    elseif st == 'cs' then
    elseif st == 'sk' then
        
        return number == 1 and 0 or (number >= 2 and number <= 4 and 1 or 2)
    elseif st == 'ga' then
        
        return number == 1 and 0 or (number == 2 and 1 or 2)
    elseif st == 'lt' then
        
        return number % 10 == 1 and number % 100 ~= 11 and 0 or (number % 10 >= 2 and (number % 100 < 10 or number % 100 >= 20) and 1 or 2)
    elseif st == 'sl' then
        
        return number % 100 == 1 and 0 or (number % 100 == 2 and 1 or (number % 100 == 3 or number % 100 == 4 and 2 or 3))
    elseif st == 'mk' then
        
        return number % 10 == 1 and 0 or 1
    elseif st == 'mt' then
        
        return number == 1 and 0 or (number == 0 or number % 100 > 1 and number % 100 < 11 and 1 or (number % 100 > 10 and number % 100 < 20 and 2 or 3))
    elseif st == 'lv' then
        
        return number == 0 and 0 or (number % 10 == 1 and number % 100 ~= 11 and 1 or 2)
    elseif st == 'pl' then
        
        return number == 1 and 0 or (number % 10 >= 2 and number % 10 <= 4 and (number % 100 < 12 or number % 100 > 14) and 1 or 2)
    elseif st == 'cy' then
        
        return number == 1 and 0 or (number == 2 and 1 or (number == 8 or number == 11 and 2 or 3))
    elseif st == 'ro' then
        
        return number == 1 and 0 or (number == 0 or number % 100 > 0 and number % 100 < 20 and 1 or 2)
    elseif st == 'ar' then
        
        return number == 0 and 0 or (number == 1 and 1 or (number == 2 and 2 or (number % 100 >= 3 and number % 100 <= 10 and 3 or (number % 100 >= 11 and number % 100 <= 99 and 4 or 5))))
    else 
        
        return 0
    end
end

return _M

