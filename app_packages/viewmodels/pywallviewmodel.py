from objc import managers
from objcbridge import BridgeBase, ObjCBridgeProtocol
from services.wallservice import WallService
import vk, json
from .pyfriendsviewmodel import UsersListTypes

class PyWallViewModelDelegate(BridgeBase):
    pass

class PyWallViewModel(ObjCBridgeProtocol):
    def __init__(self, wallService, parameters, delegateId):
        self.wallService = wallService
        self.userId = parameters.get('userId')
        print('PyWallViewModel: ' + str(self.userId))
        self.guiDelegate = PyWallViewModelDelegate(delegateId)
        if self.userId == None or self.userId == 0:
            self.userId = vk.userId()
    
    # protocol methods implementation
    def getWall(self, offset):
        response = self.wallService.getWall(offset, self.userId)
        return response
    
    def getUserInfo(self):
        if self.userId <0:
            results = self.wallService.getUserInfo()
            print('getUserInfo result: ' + json.dumps(results, indent=4))
            return results
        elif self.userId > 0:
            results = self.wallService.getBigUserInfo()
            self.wallService.updateCounters(
                                            lambda friendsCount: self.guiDelegate.friendsCountDidUpdated_(args=[friendsCount]),
                                            lambda photosCount: self.guiDelegate.photosCountDidUpdated_(args=[photosCount]),
                                            lambda groupscount: self.guiDelegate.groupsCountDidUpdated_(args=[groupscount]),
                                            lambda videoCount: self.guiDelegate.videosCountDidUpdated_(args=[videoCount]),
                                            lambda subscriptionsCount: self.guiDelegate.interestPagesCountDidUpdated_(args=[subscriptionsCount]))
            print('getUserInfo result: ' + json.dumps(results, indent=4))
            return results

    def menuTapped(self):
        managers.shared().screensManager().showMenu()

    def tappedOnPostWithId(self, identifier):
        managers.shared().screensManager().showWallPostViewControllerWithOwnerId_postId_(args=[self.userId, identifier])

    def friendsTapped(self):
        managers.shared().screensManager().showFriendsViewController_usersListType_(args=[self.userId, UsersListTypes.FRIENDS])

    def commonTapped(self):
        pass

    def subscribtionsTapped(self):
        managers.shared().screensManager().showFriendsViewController_usersListType_(args=[self.userId, UsersListTypes.SUBSCRIPTIONS])
    
    def followersTapped(self):
        managers.shared().screensManager().showFriendsViewController_usersListType_(args=[self.userId, UsersListTypes.FOLLOWERS])

    def photosTapped(self):
        managers.shared().screensManager().showPhotoAlbumsViewController_(args=[self.userId])

    def videosTapped(self):
        managers.shared().screensManager().showVideosViewController_(args=[self.userId])
    
    def groupsTapped(self):
        managers.shared().screensManager().showGroupsViewController_(args=[self.userId])

    # ObjCBridgeProtocol
    def release(self):
        pass
