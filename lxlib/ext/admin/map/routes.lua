-- Routes

Route.group({domain = app:conf('admin.domain'), prefix = app:conf('admin.uri'), middleware = 'Frozennode\\admin\\Http\\Middleware\\ValidateAdmin'}, function()
    -- hack by @Monkey: for custom route
    -- Route::group(['prefix' => 'custom'], function () {
    --     require config('admin.custom_routes_file');
    -- });
    --Admin Dashboard
    Route.get('/', {as = 'admin_dashboard', uses = 'Frozennode\\admin\\AdminController@dashboard'})
    --File Downloads
    Route.get('file_download', {as = 'admin_file_download', uses = 'Frozennode\\admin\\AdminController@fileDownload'})
    --Custom Pages
    Route.get('page/{page}', {as = 'admin_page', uses = 'Frozennode\\admin\\AdminController@page'})
    Route.group({middleware = {'Frozennode\\admin\\Http\\Middleware\\ValidateSettings', 'Frozennode\\admin\\Http\\Middleware\\PostValidate'}}, function()
        --Settings Pages
        Route.get('settings/{settings}', {as = 'admin_settings', uses = 'Frozennode\\admin\\AdminController@settings'})
        --Display a settings file
        Route.get('settings/{settings}/file', {as = 'admin_settings_display_file', uses = 'Frozennode\\admin\\AdminController@displayFile'})
        --Save Item
        Route.post('settings/{settings}/save', {as = 'admin_settings_save', uses = 'Frozennode\\admin\\AdminController@settingsSave'})
        --Custom Action
        Route.post('settings/{settings}/custom_action', {as = 'admin_settings_custom_action', uses = 'Frozennode\\admin\\AdminController@settingsCustomAction'})
        --Settings file upload
        Route.post('settings/{settings}/{field}/file_upload', {as = 'admin_settings_file_upload', uses = 'Frozennode\\admin\\AdminController@fileUpload'})
    end)
    --Switch locales
    Route.get('switch_locale/{locale}', {as = 'admin_switch_locale', uses = 'Frozennode\\admin\\AdminController@switchLocale'})
    --The route group for all other requests needs to validate admin, model, and add assets
    Route.group({middleware = {'Frozennode\\admin\\Http\\Middleware\\ValidateModel', 'Frozennode\\admin\\Http\\Middleware\\PostValidate'}}, function()
        --Model Index
        Route.get('{model}', {as = 'admin_index', uses = 'Frozennode\\admin\\AdminController@index'})
        --New Item
        Route.get('{model}/new', {as = 'admin_new_item', uses = 'Frozennode\\admin\\AdminController@item'})
        --Update a relationship's items with constraints
        Route.post('{model}/update_options', {as = 'admin_update_options', uses = 'Frozennode\\admin\\AdminController@updateOptions'})
        --Display an image or file field's image or file
        Route.get('{model}/file', {as = 'admin_display_file', uses = 'Frozennode\\admin\\AdminController@displayFile'})
        --Updating Rows Per Page
        Route.post('{model}/rows_per_page', {as = 'admin_rows_per_page', uses = 'Frozennode\\admin\\AdminController@rowsPerPage'})
        --Get results
        Route.post('{model}/results', {as = 'admin_get_results', uses = 'Frozennode\\admin\\AdminController@results'})
        --Custom Model Action
        Route.post('{model}/custom_action', {as = 'admin_custom_model_action', uses = 'Frozennode\\admin\\AdminController@customModelAction'})
        --Get Item
        Route.get('{model}/{id}', {as = 'admin_get_item', uses = 'Frozennode\\admin\\AdminController@item'})
        --File Uploads
        Route.post('{model}/{field}/file_upload', {as = 'admin_file_upload', uses = 'Frozennode\\admin\\AdminController@fileUpload'})
        --Save Item
        Route.post('{model}/{id?}/save', {as = 'admin_save_item', uses = 'Frozennode\\admin\\AdminController@save'})
        --Delete Item
        Route.post('{model}/{id}/delete', {as = 'admin_delete_item', uses = 'Frozennode\\admin\\AdminController@delete'})
        --Custom Item Action
        Route.post('{model}/{id}/custom_action', {as = 'admin_custom_model_item_action', uses = 'Frozennode\\admin\\AdminController@customModelItemAction'})
        --Batch Delete Item
        Route.post('{model}/batch_delete', {as = 'admin_batch_delete', uses = 'Frozennode\\admin\\AdminController@batchDelete'})
    end)
end)