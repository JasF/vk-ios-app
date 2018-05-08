from objc import managers
from objcbridge import BridgeBase, ObjCBridgeProtocol
from enum import IntEnum
import analytics

class UsersListTypes(IntEnum):
    FRIENDS = 1
    SUBSCRIPTIONS = 2
    FOLLOWERS = 3

class PyFriendsViewModel(ObjCBridgeProtocol):
    def __init__(self, friendsService, userId, usersListType):
        self.friendsService = friendsService
        self.userId = userId
        self.usersListType = usersListType
        print('PyFriends: ' + str(userId) + ' usersListType ' + str(usersListType))
    
    def menuTapped(self):
        managers.shared().screensManager().showMenu()

    def getFriends(self, offset):
        if self.usersListType == UsersListTypes.SUBSCRIPTIONS:
            return self.friendsService.getSubscriptions(self.userId, offset)
        elif self.usersListType == UsersListTypes.FOLLOWERS:
            return self.friendsService.getFollowers(self.userId, offset)
        return self.friendsService.getFriends(self.userId, offset)

    def tappedOnUserWithId(self, userId):
        analytics.log('Friends_segue')
        managers.shared().screensManager().showWallViewController_push_(args=[userId, True])
    
    # ObjCBridgeProtocol
    def release(self):
        print('PyFriendsViewModel release')
        pass
