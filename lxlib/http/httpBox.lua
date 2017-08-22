
local lx, _M = oo{
    _cls_ = '',
    _ext_ = 'box'
}

local app = lx.app()

function _M:reg()

    self:regDepends()
    self:regExcp()
end

function _M.__:regDepends()

    app:bond('httpExceptionBond',   'lxlib.http.bond.httpException')

    app:keep('request',             'lxlib.http.request')
    app:keep('response',            'lxlib.http.response')
    app:bind('context',             'lxlib.http.context')
    app:bind('pipeline',            'lxlib.routing.pipeline')

    app:bindFrom('lxlib.http.base', {
        baseRequest         = 'request',
        baseResponse        = 'response',
        requestHeader       = 'requestHeader',
        responseHeader      = 'responseHeader',
        responseMix         = 'responseMix',
        formHandler         = 'formHandler',
        uploadedFile        = 'uploadedFile',
    })
 
    app:bindFrom('lxlib.http', {
        'redirectResponse', 'jsonResponse'
    })

    app:single('lxlib.http.bar.verifyCsrfToken')
    app:single('lxlib.http.bar.filterIfPjax')
end

function _M.__:regExcp()

    app:bindFrom('lxlib.http.excp', {
        'httpException', 'httpResponseException',
        'notFoundHttpException', 'methodNotAllowedHttpException'
    })
end

function _M:boot()
end
 
return _M

