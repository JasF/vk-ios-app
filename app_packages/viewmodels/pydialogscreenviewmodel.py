from objcbridge import BridgeBase, ObjCBridgeProtocol
import vk
from services.messagesservice import NewMessageProtocol, MessageFlags
from random import randint
import sched, time

kTypingInterval = 5

class PyDialogScreenViewModelDelegate(BridgeBase):
    pass

class PyDialogScreenViewModel(NewMessageProtocol, ObjCBridgeProtocol):
    def __init__(self, delegateId, parameters, messagesService, dialogService):
        self.scheduler = sched.scheduler(time.time, time.sleep)
        self.typingEvent = None
        self.typingUserId = None
        self.dialogService = dialogService
        self.messagesService = messagesService
        self.messagesService.addNewMessageSubscriber(self)
        self.userId = parameters['userId']
        self.guiDelegate = PyDialogScreenViewModelDelegate(delegateId)
    
    # protocol methods from objc
    def getMessagesuserId(self, offset, userId):
        results = self.dialogService.getMessagesuserId(offset, userId)
        return results
    
    def getMessagesuserIdstartMessageId(self, offset, userId, startMessageId):
        return self.dialogService.getMessagesuserIdstartMessageId(offset, userId, startMessageId)
    
    def sendTextMessageuserId(self, text, userId):
        messageId = self.dialogService.sendTextMessageuserId(text, userId)
        timestamp = int(time.time())
        self.messagesService.saveMessageToCache(messageId, 1, vk.userId(), vk.userId(), timestamp, text, 0)
        return messageId
    
    def markAsReadmessageId(self, userId, readedMessageId):
        return self.dialogService.markAsRead(userId, readedMessageId)
    
    def handleTypingActivity(self):
        self.dialogService.sendTyping(self.userId)
    
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


    def handleTypingInDialog(self, userId, flags):
        if self.userId != userId:
            print('unknown userId: ' + str(userId) + '; current is: ' + str(self.userId))
            return
        if self.guiDelegate:
            self.guiDelegate.handleTypingInDialog_flags_end_(args=[userId,flags,False])
        
        if self.typingEvent:
            try:
                self.scheduler.cancel(self.typingEvent)
            except:
                print('scheduler.cancel(self.typingEvent) exception')
                pass
            self.typingEvent = None

        def cancelTyping(self):
            print('cancel typing. self: ' + str(self))
            self.typingEvent = None
            if self.guiDelegate:
                self.guiDelegate.handleTypingInDialog_flags_end_(args=[self.typingUserId,1,True])
        
        self.typingUserId = userId
        self.typingEvent = self.scheduler.enterabs(time.time() + kTypingInterval, 1, cancelTyping, (self,))
        self.scheduler.run()

    # ObjCBridgeProtocol
    def release(self):
        self.messagesService.removeNewMessageSubscriber(self)
        pass
