
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        config = nil,
        configFactory = nil
    }
    
    return oo(this, mt)
end

-- The config instance.
-- @var \Illuminate\Config\Repository
-- The config instance.
-- @var \Frozennode\Administrator\Config\Factory
-- Create a new Menu instance.
-- @param \Illuminate\Config\Repository            config
-- @param \Frozennode\Administrator\Config\Factory config

function _M:ctor(config, configFactory)

    self.config = config
    self.configFactory = configFactory
end

-- Gets the menu items indexed by their name with a value of the title.
-- @param table subMenu (used for recursion)
-- @return table

function _M:getMenu(subMenu)

    local config
    local menu = {}
    if not subMenu then
        subMenu = self.config:get('administrator.menu')
    end
    --iterate over the menu to build the return table of valid menu items
    for key, item in pairs(subMenu) do
        --if the item is a string, find its config
        if lf.isStr(item) then
            --fetch the appropriate config file
            config = self.configFactory:make(item)
            --if a config object was returned and if the permission passes, add the item to the menu
            if is_a(config, 'Frozennode\\Administrator\\Config\\Config') and config:getOption('permission') then
                menu[item] = config:getOption('title')
            elseif config == true then
                menu[item] = key
            end
        elseif lf.isTbl(item) then
            menu[key] = self:getMenu(item)
            --if the submenu is empty, unset it
            if lf.isEmpty(menu[key]) then
                unset(menu[key])
            end
        end
    end
    
    return menu
end

return _M

