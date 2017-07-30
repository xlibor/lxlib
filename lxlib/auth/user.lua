
local lx, _M, mt = oo{
    _cls_    = '',
    _ext_    = 'model',
    _bond_    = {'authenticatableBond', 'authorizableBond', 'canResetPasswordBond'},
    _mix_    = {'authenticatable', 'authorizable', 'canResetPassword'}
}

return _M

