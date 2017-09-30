
local lx, _M, mt = oo{
    _cls_ = '',
    _bond_ = 'socialite.userBond'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        id = nil,
        nickname = nil,
        name = nil,
        email = nil,
        avatar = nil,
        user = nil
    }
    
    return oo(this, mt)
end

function _M:getId()

    return self.id
end

-- Get the nickname / username for the user.
-- @return string

function _M:getNickname()

    return self.nickname
end

-- Get the full name of the user.
-- @return string

function _M:getName()

    return self.name
end

-- Get the e-mail address of the user.
-- @return string

function _M:getEmail()

    return self.email
end

-- Get the avatar / image URL for the user.
-- @return string

function _M:getAvatar()

    return self.avatar
end

-- Get the raw user table.
-- @return table

function _M:getRaw()

    return self.user
end

-- Set the raw user table from the provider.
-- @param  table  user
-- @return self

function _M:setRaw(user)

    self.user = user
    
    return self
end

-- Map the given table onto the user's properties.
-- @param  table  attributes
-- @return self

function _M:map(attributes)

    for key, value in pairs(attributes) do
        self[key] = value
    end
    
    return self
end

-- Determine if the given raw user attribute exists.
-- @param  string  offset
-- @return bool

function _M:offsetExists(offset)

    return tb.has(self.user, offset)
end

-- Get the given key from the raw user.
-- @param  string  offset
-- @return mixed

function _M:offsetGet(offset)

    return self.user[offset]
end

-- Set the given attribute on the raw user table.
-- @param  string  offset
-- @param  mixed  value
-- @return void

function _M:offsetSet(offset, value)

    self.user[offset] = value
end

-- Unset the given value from the raw user table.
-- @param  string  offset
-- @return void

function _M:offsetUnset(offset)

    unset(self.user[offset])
end

return _M

