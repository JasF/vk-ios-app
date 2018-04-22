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

    # protocol methods implementation
    def menuTapped(self):
        managers.shared().screensManager().showMenu()

    def tappedOnDialogWithUserId(self, userId):
        managers.shared().screensManager().showDialogViewController_(args=[userId])

    def getDialogs(self, offset):
        return self.chatListService.getDialogs(offset)

    # ObjCBridgeProtocol
    def release(self):
        self.messagesService.removeNewMessageSubscriber(self)
        pass

    # NewMessageProtocol
    def handleIncomingMessage(self, message):
        print('chatlist msg: ' + str(message) + '; delegate: ' + str(self.guiDelegate))
        if self.guiDelegate:
            self.guiDelegate.handleIncomingMessage_(args=[message])

    def handleMessageFlagsChanged(self, message):
        if self.guiDelegate:
            self.guiDelegate.handleMessageFlagsChanged_(args=[message])

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