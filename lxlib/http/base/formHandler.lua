
local lx, _M, mt = oo{
    _cls_ = ''    
}

local app, lf, tb, str = lx.kit()
local fs, env, d = lx.fs, lx.env, lx.def

local upload = require("resty.upload")

local sfind, smatch, slen = string.find, string.match, string.len

function _M:new()

    local this = {
        chunkSize = env('upload.chunkSize') or 4096,
        timeout = env('upload.timeout') or 25000,
        tmpDir = env('upload.tmpDir') or lx.dir('tmp', 'lib/upload'),
        files = {},
        params = {}
    }

    return oo(this , mt)
end

local function getExtension(fileName)

    return fileName:match(".+%.(%w+)$")
end

function _M:parseFormdata()

    local chunkSize, timeout, tmpDir = self.chunkSize, self.timeout, self.tmpDir
    local ok, msg = false, ''

    local form, err = upload:new(chunkSize)
    if not form then
        msg = "failed to new resty.upload"
        return ok, msg, err
    end

    form:set_timeout(timeout)
    
    local files, params = {}, {}
    local fieldName, uniqueName
    local file, originFileName, fileName, fileType, path, extName
    local inFileRecing
    local paramName, paramValue
    local uploadedFile
    local typ, res, err
    local part1, part2

    while true do
        typ, res, err = form:read()

        if not typ then
            ok = false; msg = "failed to read"
            return ok, msg, err
        end

        if typ == "header" then
            part1, part2 = res[1], res[2]

            if part1 == "Content-Disposition" then
                fieldName = smatch(part2, "name=\"(.-)\"")
                originFileName = smatch(part2, "filename=\"(.-)\"")
                if originFileName then
                    inFileRecing = true
                else
                    paramName = fieldName
                    inFileRecing = false
                end
            elseif part1 == "Content-Type" then
                fileType = part2
            end

            if inFileRecing and originFileName and fileType then
                extName = getExtension(originFileName)

                uniqueName = lf.guid()
                fileName = extName and uniqueName .. "." .. extName or uniqueName
                path = tmpDir .. d.dirSep .. fileName

                file, err = io.open(path, "w+")
                if err then
                    ok = false; msg = "open file error"
                    return ok, msg, err
                end
            end
        elseif typ == "body" then
            if inFileRecing then
                if file then
                    file:write(res)
                else
                    ok = false; msg = "upload file error"
                    return ok, msg, err
                end
            else
                paramValue = res
            end
        elseif typ == "part_end" then
            if inFileRecing then
                file:close()
                file = nil
                if slen(originFileName) > 0 then
                    uploadedFile = app:make('uploadedFile', path, originFileName, fileType)
                    if files[fieldName] then
                        local t = files[fieldName]
                        if #t == 0 then
                            t = {t}
                            files[fieldName] = t
                        end
                        tb.apd(t, uploadedFile)
                    else
                        files[fieldName] = uploadedFile
                    end
                end
                inFileRecing = false
                originFileName = nil
                fileType = nil
            else
                params[paramName] = paramValue
            end
        elseif typ == "eof" then
            ok = true
            break
        end
    end

    self.files = files
    self.params = params

    return ok, msg, err
end

function _M:handle()

    local ok, msg, err = self:parseFormdata()

    return ok, msg, err
end

return _M

