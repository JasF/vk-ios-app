from objc import managers
from objcbridge import BridgeBase, ObjCBridgeProtocol

class PyFriendsViewModel(ObjCBridgeProtocol):
    def __init__(self, friendsService, userId, subscriptions):
        self.friendsService = friendsService
        self.userId = userId
        self.subscriptions = subscriptions
        print('PyFriends: ' + str(userId) + ' subscriptions ' + str(subscriptions))
    
    def menuTapped(self):
        managers.shared().screensManager().showMenu()

    def getFriends(self, offset):
        if self.subscriptions:
            return self.friendsService.getSubscriptions(self.userId, offset)
        return self.friendsService.getFriends(self.userId, offset)

    def tappedOnUserWithId(self, userId):
        managers.shared().screensManager().showWallViewController_(args=[userId])
    
    # ObjCBridgeProtocol
    def release(self):
        print('PyFriendsViewModel release')
        pass
