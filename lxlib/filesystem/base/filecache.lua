
local bit = require "bit"
local ffi = require "ffi"
local bor = bit.bor;

local O_RDONLY = 0x0000
local O_WRONLY = 0x0001
local O_RDWR   = 0x0002
local O_CREAT  = 0x0040
local O_APPEND = 0x0400

local S_IRWXU=0x1c0
local S_IRUSR=0x100
local S_IWUSR=0x80
local S_IXUSR=0x40

local S_IRWXG=0x38
local S_IRGRP=0x20
local S_IWGRP=0x10
local S_IXGRP=0x8

local S_IRWXO=0x7
local S_IROTH=0x4
local S_IWOTH=0x2
local S_IXOTH=0x1

ffi.cdef[[
int rename(const char *oldpath, const char *newpath);
int system(const char *command);
int access(const char *pathname, int mode);
int unlink(const char *pathname);
int remove(const char *pathname);
static const int F_OK = 0;
char *strerror(int errnum);

int open(const char *pathname, int flags, int mode);
int close(int fd);

uint64_t read(int fd, void *buf, uint64_t count);
uint64_t write(int fd, const void *buf, uint64_t count);
]]

local function exist(filename)
    return ffi.C.access(filename, 0) == ffi.C.F_OK
end

local function pathinfo(path)
    local pos = string.len(path)
    local extpos = pos + 1
    while pos > 0 do
        local b = string.byte(path, pos)
        if b == 46 then -- 46 = char "."
            extpos = pos
        elseif b == 47 then -- 47 = char "/"
            break
        end
        pos = pos - 1
    end

    local dirname = string.sub(path, 1, pos)
    local filename = string.sub(path, pos + 1)
    extpos = extpos - pos
    local basename = string.sub(filename, 1, extpos - 1)
    local extname = string.sub(filename, extpos)
    return {
        dirname = dirname,
        filename = filename,
        basename = basename,
        extname = extname
    }
end

local function mkdir(dir)
    return os.execute("mkdir -p " .. dir)
end

local _M = {}

_M.files = {}

function _M.get_file(filename)
    local fileinfo = _M.files[filename]
    if fileinfo then
        --ngx.log(ngx.INFO, "get a fd from cache for :", filename)
        return fileinfo['fd'] 
    end
    local pathinfo = pathinfo(filename)
    local dirname = pathinfo['dirname']
    if dirname and not exist(dirname) then
        mkdir(dirname)
    end

    local flag = bor(O_RDWR, O_CREAT, O_APPEND)
    local mode = bor(S_IRUSR,S_IWUSR, S_IRGRP,S_IWGRP, S_IROTH)
    local fd = ffi.C.open(filename, flag, mode)
    if fd == -1 then
        -- TODO: 权限问题，返回相应的错误码。
        local errmsg = ffi.string(ffi.C.strerror(ffi.errno()))
        ngx.log(ngx.ERR, "failed to open file(", filename, ",",flag, ",", mode,"), err:", errmsg)
        return nil, errmsg
    end

    ngx.log(ngx.INFO, "open a new file(", filename, ",",flag, ",", mode,") ")
    return fd
end

function _M.put_file(filename, fd)
    -- 记录最后修改时间，用于对长时间没访问的文件进行清理。
    _M.files[filename] = {fd=fd, last_time=ngx.time()}
end

function _M.clean_timeout(timeout)
    local count = 0
    for filename, fileinfo in pairs(_M.files) do
        local last_time = fileinfo["last_time"]
        if last_time and ngx.time()-last_time > timeout then
            local fd = fileinfo["fd"]
            local ret = ffi.C.close(fd)
            if ret == 0 then
                ngx.log(ngx.INFO, "success to close file [", filename, "]")
            else
                ngx.log(ngx.ERR, "failed to close file [", filename, "]")
            end
            _M.files[filename] = nil
            count = count + 1
        end
    end
    return count
end

function _M.write(filename, log)
    local fd, err = _M.get_file(filename)
    if not fd then
        return err
    end
    
    local ret = ffi.C.write(fd, log, string.len(log))
    local err = nil
    if ret < 0 then
        err = ffi.string(ffi.C.strerror(ffi.errno()))
        ngx.log(ngx.ERR, "failed to write file [", filename, "], err:", err)
    end

    _M.put_file(filename, fd)
    return err
end

function _M.start_cleanup_timer(fd_expiretime)
    fd_expiretime = fd_expiretime or 600
    local delete_cache_fd_callback = function(premature)
        local ok, exp = pcall(_M.clean_timeout, fd_expiretime)
        if not ok then
            ngx.log(ngx.ERR, "call _M.clean_timeout() failed! err:", exp)
        end

        _M.start_cleanup_timer(fd_expiretime)
    end

    local clean_interval = math.floor(fd_expiretime/2)
    local next_run_time = (clean_interval - ngx.time()%clean_interval)
    ngx.log(ngx.INFO, " [delete-cache-fd-timer] next run time:", next_run_time)
    local ok, err = ngx.timer.at(next_run_time, delete_cache_fd_callback)
    if not ok then
        ngx.log(ngx.ERR, "failed to create timer: ", err)
        return
    end
end

return _M

