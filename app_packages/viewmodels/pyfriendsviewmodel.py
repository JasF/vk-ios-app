from objc import managers
from objcbridge import BridgeBase, ObjCBridgeProtocol

class PyFriendsViewModel(ObjCBridgeProtocol):
    def __init__(self, friendsService):
        self.friendsService = friendsService
    
    def menuTapped(self):
        managers.shared().screensManager().showMenu()

    def getFriends(self, offset):
        return self.friendsService.getFriends(offset)

    # ObjCBridgeProtocol
    def release(self):
        print('PyFriendsViewModel release')
        pass
