
local __ = {
    _cls_ = ''
}

-- Redirect the user to the authentication page for the provider.
-- @return redirectResponse

function __:redirect() end

-- Get the User instance for the authenticated user.
-- @return socialite.user

function __:user() end

return __

