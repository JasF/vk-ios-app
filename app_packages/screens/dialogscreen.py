from objcbridge import BridgeBase
from objc import managers
from viewmodels.dialogscreenviewmodel import DialogScreenViewModelProtocol

class DialogHandlerProtocolDelegate(BridgeBase):
    pass

class DialogHandlerProtocol(DialogScreenViewModelProtocol):
    def __init__(self, viewModel):
        self.viewModel = viewModel
        self.viewModel.setDelegate(self)
        self.guiDelegate = DialogHandlerProtocolDelegate()
    
    def hello(self, num):
        print('hello called')

    # DialogScreenViewModelProtocol:
    def handleIncomingMessage(self, userId, timestamp, body):
        self.guiDelegate.handleIncomingMessage_userId_timestamp_(args=[body,userId,timestamp])
        print('handleIncomingMessage userId: ' + str(userId) + '; body: ' + str(body) + '; timestamp: ' + str(timestamp))
        pass
