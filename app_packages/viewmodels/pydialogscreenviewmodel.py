from objc import managers
from objcbridge import BridgeBase, ObjCBridgeProtocol
import vk, json, analytics
from services.messagesservice import NewMessageProtocol, MessageFlags
from random import randint
import sched, time, random
import threading
from threading import Lock

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
        messageId = 0
        try:
            randomId = random.randint(0,2200000000)
            timestamp = int(time.time())
            self.messagesService.saveMessageToCache(randomId, 1, userId, vk.userId(), timestamp, text, 0, randomId)
            messageId = self.dialogService.sendTextMessageuserId(text, userId, randomId)
            if not isinstance(messageId, int):
                messageId = -1;
            self.messagesService.saveMessageToCache(messageId, 1, userId, vk.userId(), timestamp, text, 0, randomId)
            self.messagesService.remove(randomId)
            #self.messagesService.changeId(randomId, messageId)
        except Exception as e:
            print('sendTextMessageuserId exception: ' + str(e))
        return messageId
    
    def markAsReadmessageId(self, userId, readedMessageId):
        return self.dialogService.markAsRead(userId, readedMessageId)
    
    def handleTypingActivity(self):
        self.dialogService.sendTyping(self.userId)
    
    # NewMessageProtocol
    def handleIncomingMessage(self, message):
        self.doHandleIncomingMessage(message)
    
    def doHandleIncomingMessage(self, message):
        try:
            user_id = message.get('user_id')
            if user_id != self.userId:
                return
            isOut = message.get('out')
            id = message.get('id')
            if isOut:
                msg = self.messagesService.messageWithId(id)
                if msg:
                    #print('msg already exists! - but what first occurence missing?')
                    return
            if self.guiDelegate:
                self.guiDelegate.handleIncomingMessage_(args=[message])
        except Exception as e:
            print('doHandleIncomingMessage exception: ' + str(e))
    
    def handleEditMessage(self, message):
        if self.guiDelegate:
            self.guiDelegate.handleEditMessage_(args=[message])

    def handleMessageDeleted(self, messageId):
        if self.guiDelegate:
            self.guiDelegate.handleMessageDelete_(args=[messageId])
    
    def handleMessageFlagsChanged(self, message):
        if self.guiDelegate:
            self.guiDelegate.handleMessageFlagsChanged_(args=[message])

    def handleMessagesInReaded(self, peerId, localId):
        if self.userId != peerId:
            return
        if self.guiDelegate:
            self.guiDelegate.handleMessagesInReaded_(args=[localId])
    
    def handleMessagesOutReaded(self, peerId, localId):
        if self.userId != peerId:
            return
        if self.guiDelegate:
            self.guiDelegate.handleMessagesOutReaded_(args=[localId])

    def handleTypingInDialog(self, userId, flags):
        print('handleTypingInDialog:')
        if self.userId != userId:
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

    def tappedOnVideoWithIdownerId(self, videoId, ownerId):
        analytics.log('Dialog_video_segue')
        managers.shared().screensManager().showDetailVideoViewControllerWithOwnerId_videoId_(args=[ownerId, videoId])

    def tappedOnPhotoWithIndexmessageId(self, index, messageId):
        analytics.log('Dialog_photo_segue')
        managers.shared().screensManager().showImagesViewerViewControllerWithMessageId_index_(args=[messageId, index])
        
    # ObjCBridgeProtocol
    def release(self):
        self.messagesService.removeNewMessageSubscriber(self)
        pass
