from objc import managers
from services.wallservice import WallService
from objcbridge import BridgeBase, ObjCBridgeProtocol
import vk, json

class PyWallPostViewModel():
    def __init__(self, wallPostService, ownerId, postId):
        self.wallPostService = wallPostService
        self.postId = postId
        self.ownerId = ownerId
        print('PyWallPostViewModel ownerId: ' + str(ownerId) + '; postId: '+ str(postId))
        self.postData = None
    
    # protocol methods implementation
    def getPostData(self, offset):
        results = {}
        if not self.postData:
            self.postData = self.wallPostService.getPostById(self.postId)
            comments = self.wallPostService.getComments(self.ownerId, self.postId, offset)
            results['comments'] = comments
        if offset == 0:
            results['postData'] = self.postData
        return results
    
    # ObjCBridgeProtocol
    def release(self):
        pass
