
local lx, _M = oo{
    _cls_ = '',
    _ext_    = {
        path = 'lxlib.core.context'
    }
}

local app, lf, tb, str, new = lx.kit()
local fs = lx.fs
local throw = lx.throw

function _M:ctor()

    self.viewSharedData = {}
    if not rawget(self, 'formRequestPath') then
        self.formRequestPath = '.app.http.req.'
    end
end

function _M:view(tpl, data, engine)

    local view = app:make('view')
    view = view:make(tpl, data or {}, engine)

    self.resp:setContent(view)

    return view
end

function _M:viewShare(key, value)

    local keys = lf.isTbl(key) and key or {key = value}
    for key, value in pairs(keys) do
        self.viewSharedData[key] = value
    end
    
    return value
end

function _M:viewShared(key, default)

    return self.viewSharedData[key] or default
end

function _M:getViewShared()
    
    return self.viewSharedData
end

function _M:json(jsonable, status)

    local resp = self.resp
    resp:setContent(jsonable)

    if status then
        resp:setStatusCode(status)
    end

    return resp
end

function _M:text(text, status)
    
    local resp = self.resp
    
    resp:setContent(text)

    if status then
        resp:setStatusCode(status)
    end

    return resp
end

function _M:output(content)

    local resp = self.resp

    if lf.isObj(content) then
        if content:__is('lxlib.http.base.response') then
            self.resp = content
            
            return
        end
    end

    resp:setContent(content)
end

function _M:xml()

end

function _M:file(filePath, fileName)

    if not fs.exists(filePath) then
        throw('notFoundHttpException', filePath)
    else
        local fileData = fs.get(filePath)
        local fileSize = str.len(fileData)
        local resp = self.resp
        resp:header('Content-Type', 'application/octet-stream')
        resp:header('Content-Disposition', 'attachment;filename=' .. fileName)
        resp:header('Accept-ranges', 'bytes')
        resp:header('Accept-length', fileSize)
        resp:setContent(fileData)
    end
end

function _M:form(reqName)

    local req = app:make(self.formRequestPath .. reqName, self.req)
    req:validate()

    return req
end

function _M:_get_(key)

    local t = self.req[key]
    if t then return t end

    t = self.resp[key]
    if t then return t end

end

function _M:getRequest()

    return self.req
end

function _M:_run_(method)

    return 'getRequest'
end

function _M:__call()

    return self.req, self.resp
end

return _M

