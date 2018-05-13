from objcbridge import BridgeBase, ObjCBridgeProtocol
from objc import managers
from services.messagesservice import NewMessageProtocol
import sched, time

kTypingInterval = 5

class PyChatListViewModelDelegate(BridgeBase):
    pass

class PyChatListViewModel(NewMessageProtocol, ObjCBridgeProtocol):
    def __init__(self, delegateId, messagesService, chatListService):
        self.scheduler = sched.scheduler(time.time, time.sleep)
        self.messagesService = messagesService
        self.chatListService = chatListService
        self.typingEvent = None
        self.typingUserId = None
        self.messagesService.addNewMessageSubscriber(self)
        self.guiDelegate = PyChatListViewModelDelegate(delegateId)
        self.isActive = False
        self.needsUpdate = False
        self.count = 0
        self.dialogsCountReceived = False

    # protocol methods implementation
    def menuTapped(self):
        managers.shared().screensManager().showMenu()

    def tappedOnDialogWithUserId(self, userId):
        managers.shared().screensManager().showDialogViewController_(args=[userId])

    def getDialogs(self, offset):
        if self.dialogsCountReceived == True and offset > 0 and self.count == offset:
            return {}
        
        result = self.chatListService.getDialogs(offset)
        try:
            self.count = result['response']['count']
            self.dialogsCountReceived = True
        except Exception as e:
            print('getDialogs exception: ' + str(e))
        return result
    
    def becomeActive(self):
        self.isActive = True
        if self.needsUpdate:
            self.needsUpdate = False
            self.guiDelegate.handleNeedsUpdate()

    def resignActive(self):
        self.isActive = False
    
    # ObjCBridgeProtocol
    def release(self):
        self.messagesService.removeNewMessageSubscriber(self)
        pass

    # NewMessageProtocol
    def handleIncomingMessage(self, message):
        if not self.isActive:
            self.needsUpdate = True
            return
        print('chatlist msg: ' + str(message) + '; delegate: ' + str(self.guiDelegate))
        if self.guiDelegate:
            self.guiDelegate.handleIncomingMessage_(args=[message])

    def handleEditMessage(self, message):
        if not self.isActive:
            self.needsUpdate = True
            return
        if self.guiDelegate:
            self.guiDelegate.handleEditMessage_(args=[message])

    def handleMessageDeleted(self, messageId):
        if not self.isActive:
            self.needsUpdate = True
            return
        if self.guiDelegate:
            self.guiDelegate.handleMessageDelete_(args=[messageId])

    def handleMessageFlagsChanged(self, message):
        if not self.isActive:
            self.needsUpdate = True
            return
        if self.guiDelegate:
            self.guiDelegate.handleMessageFlagsChanged_(args=[message])

    def handleMessagesInReaded(self, peerId, localId):
        if not self.isActive:
            self.needsUpdate = True
            return
        if self.guiDelegate:
            self.guiDelegate.handleMessagesInReaded_localId_(args=[peerId, localId])
    
    def handleMessagesOutReaded(self, peerId, localId):
        if not self.isActive:
            self.needsUpdate = True
            return
        if self.guiDelegate:
            self.guiDelegate.handleMessagesOutReaded_localId_(args=[peerId, localId])

    def handleTypingInDialog(self, userId, flags):
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
