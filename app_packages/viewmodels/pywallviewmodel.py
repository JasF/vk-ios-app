from objc import managers
from objcbridge import BridgeBase, ObjCBridgeProtocol
from services.wallservice import WallService
import vk, json

class PyWallViewModel(ObjCBridgeProtocol):
    def __init__(self, wallService, parameters):
        self.wallService = wallService
        self.userId = parameters.get('userId')
        if self.userId == None or self.userId == 0:
            self.userId = vk.userId()
    
    # protocol methods implementation
    def getWall(self, offset):
        response = self.wallService.getWall(offset, self.userId)
        return response
    
    def getUserInfo(self):
        results = self.wallService.getBigUserInfo()
        #print('getUserInfo result: ' + json.dumps(results, indent=4))
        return results
    
    def menuTapped(self):
        managers.shared().screensManager().showMenu()

    def tappedOnPostWithId(self, identifier):
        managers.shared().screensManager().showWallPostViewControllerWithOwnerId_postId_(args=[self.userId, identifier])

    def friendsTapped(self):
        managers.shared().screensManager().showFriendsViewController_subscriptions_(args=[self.userId, False])
        pass

    def commonTapped(self):
        pass

    def subscribersTapped(self):
        managers.shared().screensManager().showFriendsViewController_subscriptions_(args=[self.userId, True])
        pass

    def photosTapped(self):
        managers.shared().screensManager().showPhotoAlbumsViewController_(args=[self.userId])
        pass

    def videosTapped(self):
        managers.shared().screensManager().showVideosViewController_(args=[self.userId])
        pass

    # ObjCBridgeProtocol
    def release(self):
        pass
