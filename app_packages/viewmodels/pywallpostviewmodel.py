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
        if not self.postData:
            print('get1')
            self.postData = self.wallPostService.getPostById(self.postId)
            print('get2')
            comments = self.wallPostService.getComments(self.ownerId, self.postId, offset)
            print('get3')
            print('comments is: ' + json.dumps(comments))
        return self.postData
    
    # ObjCBridgeProtocol
    def release(self):
        pass
