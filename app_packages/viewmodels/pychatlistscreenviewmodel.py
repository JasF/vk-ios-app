from objcbridge import BridgeBase
from objc import managers
from services.messagesservice import NewMessageProtocol

class PyChatListScreenViewModelDelegate(BridgeBase):
    pass

class PyChatListScreenViewModel(NewMessageProtocol):
    def __init__(self, delegateId, messagesService, chatListService):
        self.messagesService = messagesService
        self.chatListService = chatListService
        self.messagesService.addNewMessageSubscriber(self)
        self.guiDelegate = PyChatListScreenViewModelDelegate(delegateId)

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
            self.guiDelegate.handleTypingInDialog_flags_(args=[userId,flags])
