
local _M = {
    _cls_   = '',
}

local lx, tb, str

local isLxInited = false
local pregMatch = ngx.re.match
local pregReplace = ngx.re.sub

local slower, ssub = string.lower, string.sub

local caches = {
    pluralize = {},
    singularize = {}
}

local plurals = {
    merged = {},
    rules =  {
        '(s)tatus$',  '$1$2tatuses',
        '(quiz)$',  '$1zes',
        '^(ox)$',  '$1$2en',
        '([m|l])ouse$',  '$1ice',
        '(matr|vert|ind)(ix|ex)$',  '$1ices',
        '(x|ch|ss|sh)$',  '$1es',
        '([^aeiouy]|qu)y$',  '$1ies',
        '(hive)$',  '$1s',
        '(?:([^f])fe|([lr])f)$',  '$1$2ves',
        'sis$',  'ses',
        '([ti])um$',  '$1a',
        '(p)erson$',  '$1eople',
        '(m)an$',  '$1en',
        '(c)hild$',  '$1hildren',
        '(f)oot$',  '$1eet',
        '(buffal|her|potat|tomat|volcan)o$',  '$1$2oes',
        '(alumn|bacill|cact|foc|fung|nucle|radi|stimul|syllab|termin|vir)us$',  '$1i',
        'us$',  'uses',
        '(alias)$',  '$1es',
        '(analys|ax|cris|test|thes)is$',  '$1es',
        's$',  's',
        '^$',  '',
        '$',  's',
    },
    uninflected =  { 
        '.*[nrlm]ese', '.*deer', '.*fish', '.*measles', '.*ois', '.*pox', '.*sheep', 'people', 'cookie'
    },
    irregular =  { 
        ['atlas'] =  'atlases',
        ['axe'] =  'axes',
        ['beef'] =  'beefs',
        ['brother'] =  'brothers',
        ['cafe'] =  'cafes',
        ['chateau'] =  'chateaux',
        ['child'] =  'children',
        ['cookie'] =  'cookies',
        ['corpus'] =  'corpuses',
        ['cow'] =  'cows',
        ['criterion'] =  'criteria',
        ['curriculum'] =  'curricula',
        ['demo'] =  'demos',
        ['domino'] =  'dominoes',
        ['echo'] =  'echoes',
        ['foot'] =  'feet',
        ['fungus'] =  'fungi',
        ['ganglion'] =  'ganglions',
        ['genie'] =  'genies',
        ['genus'] =  'genera',
        ['graffito'] =  'graffiti',
        ['hippopotamus'] =  'hippopotami',
        ['hoof'] =  'hoofs',
        ['human'] =  'humans',
        ['iris'] =  'irises',
        ['leaf'] =  'leaves',
        ['loaf'] =  'loaves',
        ['man'] =  'men',
        ['medium'] =  'media',
        ['memorandum'] =  'memoranda',
        ['money'] =  'monies',
        ['mongoose'] =  'mongooses',
        ['motto'] =  'mottoes',
        ['move'] =  'moves',
        ['mythos'] =  'mythoi',
        ['niche'] =  'niches',
        ['nucleus'] =  'nuclei',
        ['numen'] =  'numina',
        ['occiput'] =  'occiputs',
        ['octopus'] =  'octopuses',
        ['opus'] =  'opuses',
        ['ox'] =  'oxen',
        ['penis'] =  'penises',
        ['person'] =  'people',
        ['plateau'] =  'plateaux',
        ['runner-up'] =  'runners-up',
        ['sex'] =  'sexes',
        ['soliloquy'] =  'soliloquies',
        ['son-in-law'] =  'sons-in-law',
        ['syllabus'] =  'syllabi',
        ['testis'] =  'testes',
        ['thief'] =  'thieves',
        ['tooth'] =  'teeth',
        ['tornado'] =  'tornadoes',
        ['trilby'] =  'trilbys',
        ['turf'] =  'turfs',
        ['volcano'] =  'volcanoes'
    }
}


local singulars = {
    merged = {},
    rules =  { 
        '(s)tatuses$',  '$1$2tatus',
        '^(.*)(menu)s$',  '$1$2',
        '(quiz)zes$',  '$$1',
        '(matr)ices$',  '$1ix',
        '(vert|ind)ices$',  '$1ex',
        '^(ox)en',  '$1',
        '(alias)(es)*$',  '$1',
        '(buffal|her|potat|tomat|volcan)oes$',  '$1o',
        '(alumn|bacill|cact|foc|fung|nucle|radi|stimul|syllab|termin|viri?)i$',  '$1us',
        '([ftw]ax)es',  '$1',
        '(analys|ax|cris|test|thes)es$',  '$1is',
        '(shoe|slave)s$',  '$1',
        '(o)es$',  '$1',
        'ouses$',  'ouse',
        '([^a])uses$',  '$1us',
        '([m|l])ice$',  '$1ouse',
        '(x|ch|ss|sh)es$',  '$1',
        '(m)ovies$',  '$1$2ovie',
        '(s)eries$',  '$1$2eries',
        '([^aeiouy]|qu)ies$',  '$1y',
        '([lr])ves$',  '$1f',
        '(tive)s$',  '$1',
        '(hive)s$',  '$1',
        '(drive)s$',  '$1',
        '([^fo])ves$',  '$1fe',
        '(^analy)ses$',  '$1sis',
        '(analy|diagno|^ba|(p)arenthe|(p)rogno|(s)ynop|(t)he)ses$',  '$1$2sis',
        '([ti])a$',  '$1um',
        '(p)eople$',  '$1$2erson',
        '(m)en$',  '$1an',
        '(c)hildren$',  '$1$2hild',
        '(f)eet$',  '$1oot',
        '(n)ews$',  '$1$2ews',
        'eaus$',  'eau',
        '^(.*us)$',  '$$1',
        's$',  '',
    },
    uninflected =  { 
        '.*[nrlm]ese',
        '.*deer',
        '.*fish',
        '.*measles',
        '.*ois',
        '.*pox',
        '.*sheep',
        '.*ss',
    },
    irregular =  { 
        criteria =  'criterion',
        curves =  'curve',
        emphases =  'emphasis',
        foes =  'foe',
        hoaxes =  'hoax',
        media =  'medium',
        neuroses =  'neurosis',
        waves =  'wave',
        oases =  'oasis',
    }
}


local uninflecteds = { 
    'Amoyese', 'bison', 'Borghese', 'bream', 'breeches', 'britches', 'buffalo', 'cantus',
    'carp', 'chassis', 'clippers', 'cod', 'coitus', 'Congoese', 'contretemps', 'corps',
    'debris', 'diabetes', 'djinn', 'eland', 'elk', 'equipment', 'Faroese', 'flounder',
    'Foochowese', 'gallows', 'Genevese', 'Genoese', 'Gilbertese', 'graffiti',
    'headquarters', 'herpes', 'hijinks', 'Hottentotese', 'information', 'innings',
    'jackanapes', 'Kiplingese', 'Kongoese', 'Lucchese', 'mackerel', 'Maltese', '.*?media',
    'mews', 'moose', 'mumps', 'Nankingese', 'news', 'nexus', 'Niasese',
    'Pekingese', 'Piedmontese', 'pincers', 'Pistoiese', 'pliers', 'Portuguese',
    'proceedings', 'rabies', 'rice', 'rhinoceros', 'salmon', 'Sarawakese', 'scissors',
    'sea[- ]bass', 'series', 'Shavese', 'shears', 'siemens', 'species', 'staff', 'swine',
    'testes', 'trousers', 'trout', 'tuna', 'Vermontese', 'Wenchowese', 'whiting',
    'wildebeest', 'Yengeese'
}

local function initLx()

    lx = require('lxlib')
    tb, str = lx.tb, lx.str

end

function _M.pluralize(word)

    if not isLxInited then initLx() end

    if caches.pluralize[word] then
        return caches.pluralize[word]
    end

    if not plurals.merged.irregular then
        plurals.merged.irregular = plurals.irregular
    end

    if not plurals.merged.uninflected then
        plurals.merged.uninflected = tb.merge(plurals.uninflected, uninflecteds)
    end

    if not plurals.cacheUninflected or not plurals.cacheIrregular then
        plurals.cacheUninflected = '(?:' .. str.join(plurals.merged.uninflected, '|') .. ')'
        plurals.cacheIrregular   = '(?:' .. str.join(tb.keys(plurals.merged.irregular), '|') .. ')'
    end

    local regs = pregMatch(word, '(.*)\\b(' .. plurals.cacheIrregular .. ')$', 'ijo')
    if regs then
        caches.pluralize[word] = regs[1] .. ssub(word, 1, 1) .. ssub(plurals.merged.irregular[slower(regs[2])], 2)

        return caches.pluralize[word]
    end

    regs = pregMatch(word, '^(' .. plurals.cacheUninflected .. ')$', 'ijo')
    if regs then
        caches.pluralize[word] = word

        return word
    end

    local rules = plurals.rules
    local rule, replacement
    for i = 1, #rules, 2 do
        rule, replacement = rules[i], rules[i + 1]
        if pregMatch(word, rule, 'ijo') then

            caches.pluralize[word] = pregReplace(word, rule, replacement, 'ijo')

            return caches.pluralize[word]
        end
    end
end

function _M.singularize(word)

    if not isLxInited then initLx() end

    local pat

    if caches.singularize[word] then
        return caches.singularize[word]
    end

    if not singulars.merged.uninflected then
        singulars.merged.uninflected = tb.merge(
            singulars.uninflected,
            uninflecteds
        )
    end

    if not singulars.merged.irregular then 
        singulars.merged.irregular = tb.merge(
            singulars.irregular,
            tb.flip(plurals.irregular)
        )
    end

    if not singulars.cacheUninflected or not singulars.cacheIrregular then
        singulars.cacheUninflected = '(?:' .. str.join(singulars.merged.uninflected, '|') .. ')'
        singulars.cacheIrregular = '(?:' .. str.join(tb.keys(singulars.merged.irregular), '|') .. ')'
    end

    pat = '(.*)\\b(' .. singulars.cacheIrregular .. ')$'
    local regs = pregMatch(word, pat, 'ijo')
    if regs then
        caches.singularize[word] = regs[1] .. ssub(word, 1, 1) .. ssub(singulars.merged.irregular[slower(regs[2])], 2)
        
        return caches.singularize[word]
    end

    regs = pregMatch(word, '^(' .. singulars.cacheUninflected .. ')$', 'ijo')
    if regs then
        caches.singularize[word] = word

        return word
    end

    local rules = singulars.rules
    local rule, replacement
    for i = 1, #rules, 2 do
        rule, replacement = rules[i], rules[i + 1]

        if pregMatch(word, rule, 'ijo') then

            caches.singularize[word] = pregReplace(word, rule, replacement, 'ijo')

            return caches.singularize[word]
        end
    end

    caches.singularize[word] = word

    return word

end

return _M

