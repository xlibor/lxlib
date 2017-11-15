return {
    uri = 'admin',
    domain = '',
    title = 'EST 官网管理',
    model_config_path = config_path('admin'),
    settings_config_path = config_path('admin/settings'),
    menu = {},
    permission = function()
    
    return Auth.check()
end,
    use_dashboard = false,
    dashboard_view = '',
    home_page = '',
    back_to_site_path = '/',
    login_path = 'auth/login',
    logout_path = false,
    login_redirect_key = 'redirect',
    global_rows_per_page = 20,
    locales = {},
    custom_routes_file = app_path('Http/routes/admin.php')
}