--admin index view
View.composer('admin:index', function(view)
    --get a model instance that we'll use for constructing stuff
    config = app('itemconfig')
    fieldFactory = app('admin_field_factory')
    columnFactory = app('admin_column_factory')
    actionFactory = app('admin_action_factory')
    dataTable = app('admin_datatable')
    model = config:getDataModel()
    baseUrl = route('admin_dashboard')
    route = lf.parseUrl(baseUrl)
    --add the view fields
    view.config = config
    view.dataTable = dataTable
    view.primaryKey = model:getKeyName()
    view.editFields = fieldFactory:getEditFields()
    view.arrayFields = fieldFactory:getEditFieldsArrays()
    view.dataModel = fieldFactory:getDataModel()
    view.columnModel = columnFactory:getColumnOptions()
    view.actions = actionFactory:getActionsOptions()
    view.globalActions = actionFactory:getGlobalActionsOptions()
    view.actionPermissions = actionFactory:getActionPermissions()
    view.filters = fieldFactory:getFiltersArrays()
    view.rows = dataTable:getRows(app('db'), view.filters)
    view.formWidth = config:getOption('form_width')
    view.baseUrl = baseUrl
    view.assetUrl = url('packages/summerblue/admin/')
    view.route = route['path'] .. '/'
    view.itemId = view.itemId and view.itemId or nil
end)
--admin settings view
View.composer('admin:settings', function(view)
    config = app('itemconfig')
    fieldFactory = app('admin_field_factory')
    actionFactory = app('admin_action_factory')
    baseUrl = route('admin_dashboard')
    route = lf.parseUrl(baseUrl)
    --add the view fields
    view.config = config
    view.editFields = fieldFactory:getEditFields()
    view.arrayFields = fieldFactory:getEditFieldsArrays()
    view.actions = actionFactory:getActionsOptions()
    view.baseUrl = baseUrl
    view.assetUrl = url('packages/summerblue/admin/')
    view.route = route['path'] .. '/'
end)
--header view
View.composer({'admin:partials.header'}, function(view)
    view.menu = app('admin_menu'):getMenu()
    view.settingsPrefix = app('admin_config_factory'):getSettingsPrefix()
    view.pagePrefix = app('admin_config_factory'):getPagePrefix()
    view.configType = app():bound('itemconfig') and app('itemconfig'):getType() or false
end)
--the layout view
View.composer({'admin:layouts.default'}, function(view)
    view.config = app('itemconfig')
    --set up the basic asset tables
    view.css = {}
    view.myjs = {}
    view.js = {
        jquery = '/packages/summerblue/admin/js/jquery.min.js',
        ['jquery-migrate'] = '/packages/summerblue/admin/js/jquery-migrate.min.js',
        ['jquery-ui'] = asset('packages/summerblue/admin/js/jquery/jquery-ui-1.10.3.custom.min.js'),
        customscroll = asset('packages/summerblue/admin/js/jquery/customscroll/jquery.customscroll.js')
    }
    --add the non-custom-page css assets
    if not view.page and not view.dashboard then
        view.css = view.css + {
            ['jquery-ui'] = asset('packages/summerblue/admin/css/ui/jquery-ui-1.9.1.custom.min.css'),
            ['jquery-ui-timepicker'] = asset('packages/summerblue/admin/css/ui/jquery.ui.timepicker.css'),
            select2 = asset('packages/summerblue/admin/js/jquery/select2/select2.css'),
            ['jquery-colorpicker'] = asset('packages/summerblue/admin/css/jquery.lw-colorpicker.css')
        }
    end
    --add the package-wide css assets
    view.css = view.css + {customscroll = asset('packages/summerblue/admin/js/jquery/customscroll/customscroll.css'), main = asset('packages/summerblue/admin/css/main.css'), ['main-extended'] = asset('packages/summerblue/admin/css/main-extended.css')}
    --add the non-custom-page js assets
    if not view.page and not view.dashboard then
        view.js = view.js + {
            select2 = asset('packages/summerblue/admin/js/jquery/select2/select2.js'),
            ['jquery-ui-timepicker'] = asset('packages/summerblue/admin/js/jquery/jquery-ui-timepicker-addon.js'),
            ckeditor = asset('packages/summerblue/admin/js/ckeditor/ckeditor.js'),
            ['ckeditor-jquery'] = asset('packages/summerblue/admin/js/ckeditor/adapters/jquery.js'),
            markdown = asset('packages/summerblue/admin/js/markdown.js'),
            plupload = asset('packages/summerblue/admin/js/plupload/js/plupload.full.js')
        }
        view.myjs = view.myjs + {ckeditor = asset('packages/summerblue/admin/js/ckeditor/ckeditor.js'), ['ckeditor-jquery'] = asset('packages/summerblue/admin/js/ckeditor/adapters/jquery.js'), plupload = asset('packages/summerblue/admin/js/plupload/js/plupload.full.js')}
        --localization js assets
        locale = app:conf('app.locale')
        if locale ~= 'en' then
            view.myjs = view.myjs + {
                ['plupload-l18n'] = asset('packages/summerblue/admin/js/plupload/js/i18n/' .. locale .. '.js'),
                ['timepicker-l18n'] = asset('packages/summerblue/admin/js/jquery/localization/jquery-ui-timepicker-' .. locale .. '.js'),
                ['datepicker-l18n'] = asset('packages/summerblue/admin/js/jquery/i18n/jquery.ui.datepicker-' .. locale .. '.js'),
                ['select2-l18n'] = asset('packages/summerblue/admin/js/jquery/select2/select2_locale_' .. locale .. '.js')
            }
        end
        --remaining js assets
        view.js = view.js + {
            knockout = asset('packages/summerblue/admin/js/knockout/knockout-2.2.0.js'),
            ['knockout-mapping'] = asset('packages/summerblue/admin/js/knockout/knockout.mapping.js'),
            ['knockout-notification'] = asset('packages/summerblue/admin/js/knockout/KnockoutNotification.knockout.min.js'),
            ['knockout-update-data'] = asset('packages/summerblue/admin/js/knockout/knockout.updateData.js'),
            ['knockout-custom-bindings'] = asset('packages/summerblue/admin/js/knockout/custom-bindings.js'),
            accounting = asset('packages/summerblue/admin/js/accounting.js'),
            colorpicker = asset('packages/summerblue/admin/js/jquery/jquery.lw-colorpicker.min.js'),
            history = asset('packages/summerblue/admin/js/history/native.history.js'),
            admin = asset('packages/summerblue/admin/js/admin.js'),
            settings = asset('packages/summerblue/admin/js/settings.js')
        }
    end
    view.js = view.js + {page = asset('packages/summerblue/admin/js/page.js')}
end)