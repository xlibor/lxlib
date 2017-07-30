
local lx, _M = oo{
    _cls_ = '',
    _ext_ = 'box'
}

local app = lx.app()

function _M:reg()

    app:single('events', 'lxlib.event.dispatcher')
     
end

function _M:boot()

end
 
return _M

