from objc import managers
from services.wallservice import WallService
from objcbridge import BridgeBase, ObjCBridgeProtocol
import vk

class PyWallPostViewModel():
    def __init__(self, wallPostService, postId):
        self.postId = postId
        print('postId is: ' + str(postId))
        '''
        self.userId = parameters.get('userId')
        if self.userId == None or self.userId == 0:
            self.userId = vk.userId()
        '''
    # protocol methods implementation
    def getPostData(self):
        return None#self.wallService.getWall(offset, self.userId)
    
    # ObjCBridgeProtocol
    def release(self):
        pass
