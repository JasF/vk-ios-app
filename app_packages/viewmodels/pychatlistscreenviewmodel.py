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
    # NewMessageProtocol
    def handleIncomingMessage(self, timestamp, userId, body):
        print('chatlist msg: ' + str(body) + '; delegate: ' + str(self.guiDelegate))
        if self.guiDelegate:
            self.guiDelegate.handleIncomingMessage_userId_timestamp_(args=[body,userId,timestamp])
        pass
