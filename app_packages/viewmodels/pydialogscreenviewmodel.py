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
        self.messagesService.saveMessageToCache(messageId, 1, vk.userId(), vk.userId(), timestamp, text, 0)
        return messageId
    
    def markAsReadmessageId(self, userId, readedMessageId):
        return self.dialogService.markAsRead(userId, readedMessageId)
    
    # NewMessageProtocol
    def handleIncomingMessage(self, message):
        isOut = message.get('out')
        id = message.get('id')
        if isOut:
            msg = self.messagesService.messageWithId(id)
            if msg:
                print('msg already exists!')
                return
        if self.guiDelegate:
            self.guiDelegate.handleIncomingMessage_(args=[message])
        pass
                
    
    def handleMessageFlagsChanged(self, message):
        if self.guiDelegate:
            self.guiDelegate.handleMessageFlagsChanged_(args=[message])

    # ObjCBridgeProtocol
    def release(self):
        self.messagesService.removeNewMessageSubscriber(self)
        pass
