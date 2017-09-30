
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'command'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        name = 'entrust:migration',
        description = 'Creates a migration following the Entrust specifications.'
    }
    
    return oo(this, mt)
end

-- The console command name.
-- @var string
-- The console command description.
-- @var string
-- Execute the console command.
-- @return void

function _M:fire()

    self.laravel.view:addNamespace('entrust', str.substr(__DIR__, 0, -8) .. 'views')
    local rolesTable = Config.get('entrust.roles_table')
    local roleUserTable = Config.get('entrust.role_user_table')
    local permissionsTable = Config.get('entrust.permissions_table')
    local permissionRoleTable = Config.get('entrust.permission_role_table')
    self:line('')
    self:info("Tables: {rolesTable}, {roleUserTable}, {permissionsTable}, {permissionRoleTable}")
    local message = "A migration that creates '{rolesTable}', '{roleUserTable}', '{permissionsTable}', '{permissionRoleTable}'" .. " tables will be created in database/migrations directory"
    self:comment(message)
    self:line('')
    if self:confirm("Proceed with the migration creation? [Yes|no]", "Yes") then
        self:line('')
        self:info("Creating migration...")
        if self:createMigration(rolesTable, roleUserTable, permissionsTable, permissionRoleTable) then
            self:info("Migration successfully created!")
        else 
            self:error("Couldn't create migration.\n Check the write permissions" .. " within the database/migrations directory.")
        end
        self:line('')
    end
end

-- Create the migration.
-- @param string name
-- @return bool

function _M.__:createMigration(rolesTable, roleUserTable, permissionsTable, permissionRoleTable)

    local migrationFile = base_path("/database/migrations") .. "/" .. date('Y_m_d_His') .. "_entrust_setup_tables.php"
    local usersTable = Config.get('auth.providers.users.table')
    local userModel = Config.get('auth.providers.users.model')
    local userKeyName = (new('userModel')):getKeyName()
    local data = compact('rolesTable', 'roleUserTable', 'permissionsTable', 'permissionRoleTable', 'usersTable', 'userKeyName')
    local output = self.laravel.view:make('entrust::generators.migration'):with(data):render()
    local fs = fopen(migrationFile, 'x')
    if not file_exists(migrationFile) and (fs) then
        fwrite(fs, output)
        fclose(fs)
        
        return true
    end
    
    return false
end

return _M

