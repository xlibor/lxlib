
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'box'
}

local app, lf, tb, str = lx.kit()

function _M:boot()

    self:loadViewsFrom(__DIR__ .. '/../../views', 'admin')
    self:mergeConfigFrom(__DIR__ .. '/../../config/admin.php', 'admin')
    self:loadTranslationsFrom(__DIR__ .. '/../../lang', 'admin')
    self:publishes({['__DIR__ .. '/../../config/admin.php'] = config_path('admin.php')})
    self:publishes({['__DIR__ .. '/../../../public'] = public_path('packages/summerblue/admin')}, 'public')
    --set the locale
    self:setLocale()
    app['events']:fire('admin.ready')
end

function _M:reg()

    --include our view composers, and routes to avoid issues with catch-all routes defined by users
    include __DIR__ .. '/../../viewComposers.php'
    include __DIR__ .. '/../../routes.php'
    --the admin validator
    app:single('admin_validator', function(app)
        --get the original validator class so we can set it back after creating our own
        originalValidator = LValidator.make({}, {})
        originalValidatorClass = get_class(originalValidator)
        --temporarily override the core resolver
        LValidator.resolver(function(translator, data, rules, messages)
            validator = new('validator', translator, data, rules, messages)
            validator:setUrlInstance(app:make('url'))
            
            return validator
        end)
        --grab our validator instance
        validator = LValidator.make({}, {})
        --set the validator resolver back to the original validator
        LValidator.resolver(function(translator, data, rules, messages)
            
            return new('originalValidatorClass', translator, data, rules, messages)
        end)
        --return our validator instance
        
        return validator
    end)
    --set up the shared instances
    app:single('admin_config_factory', function(app)
        
        return new('configFactory', app:make('admin_validator'), LValidator.make({}, {}), app:conf('admin'))
    end)
    app:single('admin_field_factory', function(app)
        
        return new('fieldFactory', app:make('admin_validator'), app:make('itemconfig'), app:make('db'))
    end)
    app:single('admin_datatable', function(app)
        dataTable = new('dataTable', app:make('itemconfig'), app:make('admin_column_factory'), app:make('admin_field_factory'))
        dataTable:setRowsPerPage(app:make('session.store'), app:conf('admin.global_rows_per_page'))
        
        return dataTable
    end)
    app:single('admin_column_factory', function(app)
        
        return new('columnFactory', app:make('admin_validator'), app:make('itemconfig'), app:make('db'))
    end)
    app:single('admin_action_factory', function(app)
        
        return new('actionFactory', app:make('admin_validator'), app:make('itemconfig'), app:make('db'))
    end)
    app:single('admin_menu', function(app)
        
        return new('menu', app:make('config'), app:make('admin_config_factory'))
    end)
end

-- Sets the locale if it exists in the session and also exists in the locales option.

function _M:setLocale()

    local locale = app:get('session'):get('admin_locale')
    if locale then
        app:setLocale(locale)
    end
end

return _M

