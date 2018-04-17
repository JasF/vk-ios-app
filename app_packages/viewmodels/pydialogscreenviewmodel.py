from objcbridge import BridgeBase
from services.messagesservice import NewMessageProtocol

class PyDialogScreenViewModelDelegate(BridgeBase):
    pass

class PyDialogScreenViewModel(NewMessageProtocol):
    def __init__(self, messagesService):
        self.messagesService = messagesService
        self.messagesService.addNewMessageSubscriber(self)
        self.guiDelegate = PyDialogScreenViewModelDelegate()
    
    # NewMessageProtocol
    def handleIncomingMessage(self, timestamp, userId, body):
        print('msg: ' + str(body) + '; guiDelegate: ' + str(self.guiDelegate))
        if self.guiDelegate:
            self.guiDelegate.handleIncomingMessage_userId_timestamp_(args=[body,userId,timestamp])
        pass
