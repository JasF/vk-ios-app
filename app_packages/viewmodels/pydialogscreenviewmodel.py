from objcbridge import BridgeBase, ObjCBridgeProtocol
import vk
from services.messagesservice import NewMessageProtocol, MessageFlags
from random import randint
import time

class PyDialogScreenViewModelDelegate(BridgeBase):
    pass

class PyDialogScreenViewModel(NewMessageProtocol, ObjCBridgeProtocol):
    def __init__(self, delegateId, parameters, messagesService, dialogService):
        self.dialogService = dialogService
        self.messagesService = messagesService
        self.messagesService.addNewMessageSubscriber(self)
        self.userId = parameters['userId']
        self.guiDelegate = PyDialogScreenViewModelDelegate(delegateId)
    
    # protocol methods from objc
    def getMessagesuserId(self, offset, userId):
        return self.dialogService.getMessagesuserId(offset, userId)
    
    def getMessagesuserIdstartMessageId(self, offset, userId, startMessageId):
        return self.dialogService.getMessagesuserIdstartMessageId(offset, userId, startMessageId)
    
    def sendTextMessageuserId(self, text, userId):
        messageId = self.dialogService.sendTextMessageuserId(text, userId)
        timestamp = int(time.time())
        self.messagesService.saveMessageToCache(messageId, 1, vk.userId(), vk.userId(), timestamp, text)
        return messageId
    
    # NewMessageProtocol
    def handleIncomingMessage(self, messageId, nFlags, userId, timestamp, text):
        isOut = True if MessageFlags(nFlags) & MessageFlags.OUTBOX else False
        if isOut:
            msg = self.messagesService.messageWithId(messageId)
            if msg:
                print('msg already exists!')
                return
            #print('skipping due to outgoing message')
            #return
        if self.guiDelegate:
            self.guiDelegate.handleIncomingMessage_userId_timestamp_isOut_(args=[text,userId,timestamp,isOut])
        pass

    # ObjCBridgeProtocol
    def release(self):
        self.messagesService.removeNewMessageSubscriber(self)
        pass
