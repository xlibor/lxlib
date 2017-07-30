
return function(route)
    
    local lx = require('lxlib')
    local app = lx.app()
    local namespace = app:conf('app.namespace')

    route:namespace(namespace):bar('web'):group(function()

        route:get('home', 'home@index')
        route:get('login', 'auth.login@showLoginForm'):name('login')
        route:post('login', 'auth.login@login')
        route:add('logout', 'auth.login@logout'):name('logout')

        route:get('reg', 'auth.reg@showRegForm'):name('reg')
        route:post('reg', 'auth.reg@reg')

        route:get('pwd/reset', 'auth.forgotPwd@showLinkRequestForm')
            :name('pwd.request')
        route:post('pwd/email', 'auth.forgotPwd@sendResetLinkEmail')
            :name('pwd.email')
        route:get('pwd/reset/{token}', 'auth.resetPwd@showResetForm')
            :name('pwd.reset')
        route:post('pwd/reset', 'auth.resetPwd@reset')
    end)
end

