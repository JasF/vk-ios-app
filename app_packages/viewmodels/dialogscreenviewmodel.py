from services.messagesservice import NewMessageProtocol

class DialogScreenViewModelProtocol:
    def handleIncomingMessage(self, userId, timestamp, body):
        pass

class DialogScreenViewModel(NewMessageProtocol):
    def __init__(self, messagesService):
        self.messagesService = messagesService
        self.messagesService.addNewMessageSubscriber(self)
        self.delegate = None

    def setDelegate(self, delegate):
        self.delegate = delegate
    
    # NewMessageProtocol
    def handleIncomingMessage(self, timestamp, userId, body):
        if self.delegate:
            self.delegate.handleIncomingMessage(userId, timestamp, body)
        pass
