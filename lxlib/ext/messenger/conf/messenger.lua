

local conf = {
    models = {
        message = {
            model = 'messenger.model.message',
            table = 'message',
        },
        participant = {
            model = 'messenger.model.participant',
            table = 'participant'
        },
        thread = {
            model = 'messenger.model.thread',
            table = 'thread'
        }
    }
}

return conf

