from objc import managers
from services.wallservice import WallService
from objcbridge import BridgeBase, ObjCBridgeProtocol
import vk, json
from constants import g_CommentsCount

kOffsetForPreloadLatestComments = -1
class PyWallPostViewModel():
    def __init__(self, wallPostService, ownerId, postId):
        self.wallPostService = wallPostService
        self.postId = postId
        self.ownerId = ownerId
        print('PyWallPostViewModel ownerId: ' + str(ownerId) + '; postId: '+ str(postId))
        self.postData = None
    
    # protocol methods implementation
    def getCachedPost(self):
        if not self.postData:
            self.postData = self.wallPostService.getPostById(self.ownerId, self.postId)
        return {'postData': self.postData}
    
    def getPostData(self, offset):
        results = {}
        commentsOffset = offset
        if offset == kOffsetForPreloadLatestComments:
            commentsOffset = 0
            count = 0
            try:
                count = self.postData['response']['items'][0]['comments']['count']
                commentsOffset = count - g_CommentsCount
                if commentsOffset < 0:
                    commentsOffset = 0
            except:
                print('failed get comments count for post ')
        comments = self.wallPostService.getComments(self.ownerId, self.postId, commentsOffset, g_CommentsCount)
        results['comments'] = comments
        return results
    
    # ObjCBridgeProtocol
    def release(self):
        pass
