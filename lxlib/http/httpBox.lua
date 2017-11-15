
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

    app:bind('formRequest',         'lxlib.http.formRequest')

    app:bindFrom('lxlib.http.base', {
        'responseMix', 'uploadedFile'
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

