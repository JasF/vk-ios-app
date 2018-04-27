from objc import managers
from objcbridge import BridgeBase, ObjCBridgeProtocol
from services.wallservice import WallService
import vk, json

class PyVideosViewModel(ObjCBridgeProtocol):
    def __init__(self, videosService, ownerId):
        self.videosService = videosService
        self.ownerId = ownerId
        self.endReached = False
    
    # protocol methods implementation
    def getVideos(self, offset):
        if self.endReached:
            return {}
        
        response, count = self.videosService.getVideos(self.ownerId, offset)
        if count == 0:
            self.endReached = True
        return response
    
    def menuTapped(self):
        managers.shared().screensManager().showMenu()

    def tappedOnVideoWithIdownerId(self, videoId, ownerId):
        managers.shared().screensManager().showDetailVideoViewControllerWithOwnerId_videoId_(args=[ownerId, videoId])
    
    # ObjCBridgeProtocol
    def release(self):
        pass