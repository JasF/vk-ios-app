from objc import managers
from objcbridge import BridgeBase, ObjCBridgeProtocol

class PyFriendsViewModel(ObjCBridgeProtocol):
    def __init__(self, friendsService, userId):
        self.friendsService = friendsService
        self.userId = userId
        print('PyFriends: ' + str(userId))
    
    def menuTapped(self):
        managers.shared().screensManager().showMenu()

    def getFriends(self, offset):
        return self.friendsService.getFriends(self.userId, offset)

    def tappedOnUserWithId(self, userId):
        managers.shared().screensManager().showWallViewController_(args=[userId])
    
    # ObjCBridgeProtocol
    def release(self):
        print('PyFriendsViewModel release')
        pass
