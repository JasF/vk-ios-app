from objcbridge import BridgeBase, ObjCBridgeProtocol
from services.messagesservice import NewMessageProtocol

class PyDialogScreenViewModelDelegate(BridgeBase):
    pass

class PyDialogScreenViewModel(NewMessageProtocol, ObjCBridgeProtocol):
    def __init__(self, delegateId, messagesService, dialogService):
        self.dialogService = dialogService
        self.messagesService = messagesService
        self.messagesService.addNewMessageSubscriber(self)
        self.guiDelegate = PyDialogScreenViewModelDelegate(delegateId)
    
    # protocol methods from objc
    def getMessagesuserId(self, offset, userId):
        return self.dialogService.getMessagesuserId(offset, userId)
    
    def getMessagesuserIdstartMessageId(self, offset, userId, startMessageId):
        return self.dialogService.getMessagesuserIdstartMessageId(offset, userId, startMessageId)
    
    def sendTextMessageuserId(self, text, userId):
        return self.dialogService.sendTextMessageuserId(text, userId)
    
    # NewMessageProtocol
    def handleIncomingMessage(self, timestamp, userId, body):
        print('msg: ' + str(body) + '; guiDelegate: ' + str(self.guiDelegate))
        if self.guiDelegate:
            self.guiDelegate.handleIncomingMessage_userId_timestamp_(args=[body,userId,timestamp])
        pass

    # ObjCBridgeProtocol
    def release(self):
        self.messagesService.removeNewMessageSubscriber(self)
        pass
