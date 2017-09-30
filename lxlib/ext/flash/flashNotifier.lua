
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
    }
    
    return oo(this, mt)
end

-- Flash an information message.
-- @param  string message
-- @return self

function _M:info(message)

    self:message(message, 'info')
    
    return self
end

-- Flash a success message.
-- @param  string message
-- @return self

function _M:success(message)

    self:message(message, 'success')
    
    return self
end

-- Flash an error message.
-- @param  string message
-- @return self

function _M:error(message)

    self:message(message, 'danger')
    
    return self
end

-- Flash a warning message.
-- @param  string message
-- @return self

function _M:warning(message)

    self:message(message, 'warning')
    
    return self
end

-- Flash an overlay modal.
-- @param  string message
-- @param  string title
-- @param  string level
-- @return self

function _M:overlay(message, title, level)

    level = level or 'info'
    title = title or 'Notice'
    self:message(message, level)
    self:flash('flash_notification.overlay', true)
    self:flash('flash_notification.title', title)
    
    return self
end

-- Flash a general message.
-- @param  string message
-- @param  string level
-- @return self

function _M:message(message, level)

    level = level or 'info'
    self:flash('flash_notification.message', message)
    self:flash('flash_notification.level', level)
    
    return self
end

-- Add an "important" flash to the session.
-- @return self

function _M:important()

    self:flash('flash_notification.important', true)
    
    return self
end

function _M:flash(message, level)

    local session = app:get('session')
    session:flash(message, level)
end

return _M

