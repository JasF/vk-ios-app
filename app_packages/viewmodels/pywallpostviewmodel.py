from objc import managers
from services.wallservice import WallService
from objcbridge import BridgeBase, ObjCBridgeProtocol
import vk

class PyWallPostViewModel():
    def __init__(self, wallPostService, postId):
        self.wallPostService = wallPostService
        self.postId = postId
        self.postData = self.wallPostService.getPostById(postId)
    
    # protocol methods implementation
    def getPostData(self):
        if not self.postData:
            self.postData = self.wallPostService.getPostById(postId)
        return self.postData
    
    # ObjCBridgeProtocol
    def release(self):
        pass
