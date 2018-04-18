from objcbridge import BridgeBase, ObjCBridgeProtocol
from services.messagesservice import NewMessageProtocol, MessageFlags

class PyDialogScreenViewModelDelegate(BridgeBase):
    pass

class PyDialogScreenViewModel(NewMessageProtocol, ObjCBridgeProtocol):
    def __init__(self, delegateId, parameters, messagesService, dialogService):
        self.dialogService = dialogService
        self.userId = parameters['userId']
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
    def handleIncomingMessage(self, messageId, nFlags, userId, timestamp, text):
        flags = MessageFlags(nFlags)
        if flags.OUTBOX:
            print('skipping due to outgoing message')
            return
        print('msg: ' + str(text) + '; self.userId:' + str(self.userId) + '; incomingUserId: ' + str(userId))
        if self.guiDelegate:
            self.guiDelegate.handleIncomingMessage_userId_timestamp_(args=[text,userId,timestamp])
        pass

    # ObjCBridgeProtocol
    def release(self):
        self.messagesService.removeNewMessageSubscriber(self)
        pass
