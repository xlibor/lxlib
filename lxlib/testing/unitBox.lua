
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'box'
}

local app, lf, tb, str = lx.kit()

function _M:reg()
    
    app:bindFrom('lxlib.testing', {
        ['unit.assert']         = 'assert',
        ['unit.testCase']       = 'testCase',
        ['unit.testSuite']      = 'testSuite',
        ['unit.testResult']     = 'testResult',
        ['unit.testFailure']    = 'testFailure',
        ['unit.runner']         = 'runner',
        ['unit.loader']         = 'loader',
        ['unit.env']            = 'env',
        ['unit.constraint']     = 'constraint',
        ['unit.comparator']     = 'comparator',
        ['unit.exporter']       = 'exporter',
        ['unit.resultPrinter']  = 'resultPrinter',
    })

    app:bindFrom('lxlib.testing.filter', {
        ['unit.filter.testIterator']       = 'testIterator',
    })

    app:bindFrom('lxlib.testing.constraint', {
        ['unit.constraint.isEqual']             = 'isEqual',
        ['unit.constraint.isTrue']              = 'isTrue',
        ['unit.constraint.isFalse']             = 'isFalse',
        ['unit.constraint.logicalAnd']          = 'logicalAnd',
        ['unit.constraint.logicalNot']          = 'logicalNot',
        ['unit.constraint.logicalOr']           = 'logicalOr',
        ['unit.constraint.count']               = 'count',
        ['unit.constraint.isInstanceOf']        = 'isInstanceOf',
        ['unit.constraint.isEmpty']             = 'isEmpty',
        ['unit.constraint.isNull']              = 'isNull',
        ['unit.constraint.isJson']              = 'isJson',
        ['unit.constraint.isType']              = 'isType',
        ['unit.constraint.isAnything']          = 'isAnything',
        ['unit.constraint.arrayHasKey']         = 'arrayHasKey',
        ['unit.constraint.isIdentical']         = 'isIdentical',
        ['unit.constraint.stringContains']      = 'stringContains',
        ['unit.constraint.eachableContains']    = 'eachableContains',
        ['unit.constraint.greaterThan']         = 'greaterThan',
        ['unit.constraint.jsonMatches']         = 'jsonMatches',
        ['unit.constraint.exception']           = 'exception',
    })

    app:bindFrom('lxlib.testing.mock', {
        ['unit.mock.mockBuilder']               = 'mockBuilder',
        ['unit.mock.mockedClass']               = 'mockedClass',
        ['unit.mock.generator']                 = 'generator',
        ['unit.mock.builder.invocationMocker']  = 'builder.invocationMocker',
        ['unit.mock.matcher']                   = 'matcher',
        ['unit.mock.invocationMocker']          = 'invocationMocker',
    })

    app:bindFrom('lxlib.testing.mock.matcher', {
        ['unit.mock.matcher.anyInvokedCount']           = 'anyInvokedCount',
        ['unit.mock.matcher.anyParameters']             = 'anyParameters',
        ['unit.mock.matcher.consecutiveParameters']     = 'consecutiveParameters',
        ['unit.mock.matcher.invokedAtIndex']            = 'invokedAtIndex',
        ['unit.mock.matcher.invokedAtLeastCount']       = 'invokedAtLeastCount',
        ['unit.mock.matcher.invokedAtLeastOnce']        = 'invokedAtLeastOnce',
        ['unit.mock.matcher.invokedAtMostCount']        = 'invokedAtMostCount',
        ['unit.mock.matcher.invokedCount']              = 'invokedCount',
        ['unit.mock.matcher.invokedRecorder']           = 'invokedRecorder',
        ['unit.mock.matcher.methodName']                = 'methodName',
        ['unit.mock.matcher.parameters']                = 'parameters',
        ['unit.mock.matcher.statelessInvocation']       = 'statelessInvocation',
    })

    app:bindFrom('lxlib.testing.mock.stub', {
        ['unit.mock.stub.consecutiveCalls']     = 'consecutiveCalls',
        ['unit.mock.stub.exception']            = 'exception',
        ['unit.mock.stub.return']               = 'return',
        ['unit.mock.stub.returnArgument']       = 'returnArgument',
        ['unit.mock.stub.returnCallback']       = 'returnCallback',
        ['unit.mock.stub.returnReference']      = 'returnReference',
        ['unit.mock.stub.returnSelf']           = 'returnSelf',
        ['unit.mock.stub.returnValueMap']       = 'returnValueMap',
    })

    app:bindFrom('lxlib.testing.mock.invocation', {
        ['unit.mock.invocation.object']         = 'object',
        ['unit.mock.invocation.static']         = 'static',
    })

    self:regBond()
    self:regExcp()
end

function _M:regBond()

    app:bondFrom('lxlib.testing.bond', {
        ['unit.test']                   = 'test',
        ['unit.testListener']           = 'testListener',
    })

    app:bondFrom('lxlib.testing.bond.mock', {
        ['unit.mock.verifiable']                = 'verifiable',
        ['unit.mock.mockObject']                = 'mockObject',
        ['unit.mock.invocation']                = 'invocation',
        ['unit.mock.invokable']                 = 'invokable',
        ['unit.mock.stub']                      = 'stub',
        ['unit.mock.stub.matcherCollection']    = 'stub.matcherCollection',
        ['unit.mock.matcher.invocation']        = 'matcher.invocation',
    })

    app:bondFrom('lxlib.testing.bond.mock.builder', {
        ['unit.mock.builder.identity']          = 'identity',
        ['unit.mock.builder.match']             = 'match',
        ['unit.mock.builder.methodNameMatch']   = 'methodNameMatch',
        ['unit.mock.builder.namespace']         = 'namespace',
        ['unit.mock.builder.parametersMatch']   = 'parametersMatch',
        ['unit.mock.builder.stub']              = 'stub',
    })

end

function _M:regExcp()

    app:bindFrom('lxlib.testing.excp', {
        ['unit.exception']                  = 'unitException',
        ['unit.error']                      = 'unitError',
        ['unit.invalidArgumentExcpeiton']   = 'unitInvalidArgumentException',
        ['unit.assertionFailedError']       = 'assertionFailedError',
        ['unit.expectationFailedException'] = 'expectationFailedException',
        ['unit.exceptionWrapper']           = 'exceptionWrapper',
        ['unit.comparisonFailure']          = 'comparisonFailure',
        ['unit.mock.exception']             = 'mockException',
    })

    app:single('unit.invalidArgumentHelper',
        'lxlib.testing.util.invalidArgumentHelper',
        ''
    )
    
end

function _M:boot()

    app:regCmds(function(cmder)

        app:bind('unit.creator', 'lxlib.db.unit.creator')

        cmder:group({ns = 'lxlib.testing.cmd', lib = false, app = true}, function()
            cmder:add('{unit}/{run}|unit', '$1ManageCmd@$2')
            cmder:add('make/{test}', '$1MakeCmd@make')
        end)
    end)

end

return _M

