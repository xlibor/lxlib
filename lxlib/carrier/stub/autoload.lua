
local lx = require('lxlib')
local fs = lx.fs

local vendorPath = lx.getPath(true)
local appPath = fs.dirname(vendorPath)
local appName = fs.basename(appPath)
local vendor = appName .. '.'

local namespace = {
{{namespaces}}
}

return namespace

