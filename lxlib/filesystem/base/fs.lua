
local _M = {
    _cls_ = ''
}

local base = require('lxlib.resty.path')

local io, os = io, os
local open, popen = io.open, io.popen
local exec = os.execute
local ssub, smatch = string.sub, string.match
local fmt = string.format

for k, v in pairs(base) do
    _M[k] = v
end

_M.isWin = _M.IS_WINDOWS

-- linux
if not _M.exists then 

_M.useBase = true

function _M.exists(path)

    local file, err = open(path, "r")

    if file then
        file:close()
        return path
    else
        return false, err
    end
end

function _M.isfile(path)

    if _M.exists(path) and not _M.isdir(path) then
        return true
    else
        return false
    end
end

function _M.isdir(path)

    local cmd = 'find "'..path..'" -mindepth 0 -maxdepth 0 -type d'

    local pfile = popen(cmd)

    if pfile then
        pfile:close()
        return true
    else
        return false
    end
end

function _M.dirs(dir, style, filter)

    local ret = {}

    local pfile = popen('find "'..dir..'" -mindepth 1 -maxdepth 1 -type d')

    local fullStyle, normalStyle, pathStyle
    if style == 'f' then
        fullStyle = true
    elseif style == 'n' then
        normalStyle = true
    elseif style == 'p' then
        pathStyle = true
    end

    local t

    for each in pfile:lines() do
        if normalStyle then
            t = smatch(each, '.*/(%S*)/?')
            if t then each = t end
        end

        if filter then
            each = filter(each)
        end

        if each then
            tapd(ret, each)
        end
    end

    pfile:close()

    return ret
end

function _M.files(dir, style, filter)

    local ret = {}

    local cmd = 'find "' .. dir .. '" -mindepth 1 -maxdepth 1 -type f'
 
    local pfile = popen(cmd)
     
    if not pfile then
        error('popen files fail')
    end

    local fullStyle, normalStyle, pathStyle
    if style == 'f' then
        fullStyle = true
    elseif style == 'n' then
        normalStyle = true
    elseif style == 'p' then
        pathStyle = true
    end

    local t
    
    for each in pfile:lines() do
        if normalStyle then
            t = smatch(each, '.*/(%S*)')
            if t then each = t end
        elseif pathStyle then
            t = smatch(each, '(.*)/%S*')
            if t then each = t end
        end

        if filter then
            each = filter(each)
        end

        if each then
            tapd(ret, each)
        end
    end

    pfile:close()

    return ret
end

function _M.mkdir(dir)

    local pfile = popen('mkdir -p ' .. dir)

    if pfile then
        pfile:close()
        return false
    else
        pfile:close()
        return true
    end

end

function _M.remove(path)

    return os.remove(path)
end

function _M.copy(src, dst, opt)

    local vt = type(opt)
    if vt == 'boolean' then
        opt = {overwrite = opt}
    elseif vt == 'nil' then
        opt = {overwrite = false}
    end

    local overwrite = opt.overwrite
    local recurse = opt.recurse

    local optStr = '-'
    if recurse then
        optStr = optStr .. 'r'
    end
    if overwrite then
        optStr = optStr .. 'f'
    end

    if optStr == '-' then
        optStr = ''
    end

    local cmd = fmt('cp %s %s %s', optStr, src, dst)

    return exec(cmd)
end

function _M.currentdir()

    local pfile = popen('pwd')
    
    if pfile then
        local t = pfile:read("*a")
        if ssub(t, -1) == '\n' then
            t = ssub(t, 1, -2)
        end
        pfile:close()
        return t
    else
        pfile:close()
        return
    end
end

function _M.fullpath(P)

  if not _M.isfullpath(P) then 
    P = _M.normolize_sep(P)
    local ch1, ch2 = P:sub(1,1), P:sub(2,2)
    if ch1 == '~' then --  ~\temp
      P = _M.join(_M.user_home(), P:sub(2))
    elseif _M.iswin and (ch1 == _M.DIR_SEP) then -- \temp => c:\temp
      local root = _M.root(_M.currentdir())
      P = _M.join(root, P)
    else
      P = _M.join(_M.currentdir(), P)
    end
  end

  return _M.normolize(P)
end

end 
--linux

function _M.readfile(path)

    local file, err = open(path, "rb")
    if not file then return nil, err end
    local content = file:read("*a")
    file:close()
    
    return content
end

function _M.writefile(path, content, append)
    
    local mode = append and "a+b" or "w+b"

    local file, err = open(path, mode)
    if not file then
        path = tostring(path) or ''
        err = err or 'unknown'
        error('open file[' .. path .. '] failed:' .. err)
    end

    file:write(content)
    file:close()
end

function _M.deleteDir(path)

    if not path then
        error('invalid path.')
    end

    if _M.isWin then
        exec('rd /s/q ' .. path)
    else
        exec('rm -rf ' .. path)
    end

end

return _M

