
local isWin = (package.config:sub(1,1) == '\\')
local dirSep = isWin and '\\' or '/'

local define = {
    eq = '=', neq ='<>', ne = '<>',
    gt ='>', gte = '>=', ge = '>=',
    lt = '<', lte = '<=', le = '<=',
    like = 'like', nl = 'not like',
    in_ = 'in', notin = 'not in', ni = 'not in',
    btw = 'between', nb = 'not between',
    not_ = 'not', is = 'is', isnot = 'is not',
    asc = 'asc', desc = 'desc',
    count = 'count', sum = 'sum',
    avg = 'avg', first = 'first', last = 'last',
    max = 'max', min = 'min',
    innerJoin = 'inner join', leftJoin = 'left join',
    rightJoin = 'right join', fullJoin = 'full join',
    outerJoin = 'outer join', join = 'join',
    insert = 'insert', replace = 'replace',
    get = 'get', post = 'post',
    dirSep = dirSep
}

return define

