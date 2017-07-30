
local _M = {
    _cls_    = ''    
}

local base = require('lxlib.filesystem.base.fs')
local fsCache = require('lxlib.filesystem.base.fsffi')
local str = require('lxlib.base.str')
local sfind, slen, ssub = string.find, string.len, string.sub

_M.base = base

function _M.exists(path)
     
    if path then
        return base.exists(path)
    else
        return 
    end
end

_M.exist = _M.exists

function _M.isFile(path)

    return base.isfile(path) and true or false
end

function _M.isDir(path)

    return base.isdir(path) and true or false
end

function _M.isLink(path)

    return base.islink(path) and true or false
end

function _M.isEmpty(path)

end

function _M.makeDir(path)

    return base.mkdir(path)
end

function _M.get(path)

    return base.readfile(path)
end

function _M.put(path, content, append)
    
    return base.writefile(path, content, append)
end

function _M.prepend(path, data)
 
end

function _M.append(path, data)
 
end

function _M.delete(path)

    if type(path) == 'table' then
        for _, v in ipairs(path) do
            base.remove(v)
        end
    else
        base.remove(path)
    end
end

function _M.copy(src, dst, opt)

    if type(opt) == 'string' then
        local overwrite, recurse
        if sfind(opt, 'f') then overwrite = true end
        if sfind(opt, 'r') then recurse = true end
        opt = {overwrite = overwrite, recurse = recurse}
    end
     
    return base.copy(src, dst, opt)
end

function _M.fileName(path)

    local baseName, ext = _M.baseName(path), _M.extension(path)
    local t = baseName:gsub(ext, '')
    return t
end

_M.name = _M.fileName

function _M.dirName(path)

    return base.dirname(path)
end

_M.dirname = _M.dirName

function _M.baseName(path)

    return base.basename(path)
end

_M.basename = _M.baseName

function _M.fullPath(path)

    return base.fullpath(path)
end

_M.fullpath = _M.fullPath

function _M.extension(path)

    return base.extension(path)
end

function _M.pathInfo(path)

    local ext = base.extension(path)
    if ext then
        ext = ssub(ext, 2)
    end
    local name = base.basename(path)
    if sfind(name, '.', nil, true) then
        name = ssub(name, 1, str.rfindp(name, '.') - 1)
    end

    return base.dirname(path), name, ext
end

_M.pathinfo = _M.pathInfo

function _M.fileType(path)

end
 
function _M.mimeType(path)

end

function _M.size(path)

    return base.size(path)
end

function _M.ctime(path)

    return base.ctime(path)
end

function _M.atime(path)

    return base.atime(path)
end

function _M.mtime(path)

    return base.mtime(path)
end

function _M.isWritable(path)

end

function _M.files(dir, style, filter, recurse)

    if not style then
        style = 'f'
    else
        if slen(style) > 1 then
            style = ssub(style, 1, 1)
        end
    end

    if base.useBase then
        local ok, ret
        for i = 1, 9 do
            ok, ret = pcall(base.files, dir, style, filter)
            if ok then 
                break
            end
        end

        return ret 
    end

    dir = dir .. '/*'
    local ret = {}

    local addFile = function(file, mode)
        if mode == 'file' then
            if filter then
                file = filter(file)
            end
            if file then
                tapd(ret, file)
            end
        end
    end

    style = style .. 'm'
    local opt = {
        param = style,
        recurse = recurse
    }

    base.each(dir, addFile, opt)

    return ret
end

function _M.allFiles(dir, style, filter)

    return _M.files(dir, style, filter, true)
end

function _M.dirs(dir, style, filter)

    if not style then
        style = 'f'
    else
        if slen(style) > 1 then
            style = ssub(style, 1, 1)
        end
    end

    if base.useBase then
        return base.dirs(dir, style, filter)
    end

    dir = dir .. '/*'
    local ret = {}

    local addFile = function(file, mode)
        if mode == 'directory' then
            if filter then
                file = filter(file)
            end
            if file then
                tapd(ret, file)
            end
        end
    end

    style = style .. 'm'

    local opt = {
        param = style,
        recurse = false
    }

    base.each(dir, addFile, opt)

    return ret
end

function _M.copyDir(dir, dest, options)

end

function _M.deleteDir(dir, preserve)

    return base.deleteDir(dir, preserve)
end

function _M.cleanDir(dir)

end

function _M.hasDirEnd(path)

end
 
function _M.removeDirEnd(path)

end
 
function _M.ensureDirEnd(path)

end

function _M.normalize(path)

end

function _M.join(...)

    return base.join(...)
end

function _M.remove(path, options)

    return base.remove(path, options)
end


function _M.rename(path, newName, force)

end

function _M.isWin()

    return base.isWin
end

function _M.userHome()

    return base.user_home()
end

function _M.currDir()

    return base.currentdir()
end

function _M.split(path)

    return base.split(path)
end

function _M.ensureDir(file)

    local dir = _M.dirName(file)
    if dir then
        if not _M.exists(dir) then
            _M.makeDir(dir)
        end
    end
end

function _M.writeCache(file, content)

    fsCache.write(file, content)
end

return _M

