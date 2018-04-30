from objc import managers
from services.wallservice import WallService
from objcbridge import BridgeBase, ObjCBridgeProtocol
import vk, json

g_count = 40
kOffsetForPreloadLatestComments = -1
# https://vk.com/dev/wall.getComments
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
            self.postData = self.wallPostService.getPostById(self.ownerId, self.postId)
        commentsOffset = offset
        if offset == kOffsetForPreloadLatestComments:
            commentsOffset = 0
            count = 0
            try:
                print('self.postData ' + json.dumps(self.postData, indent=4))
                count = self.postData['response']['items'][0]['comments']['count']
                commentsOffset = count - g_count
                if commentsOffset < 0:
                    commentsOffset = 0
            except:
                print('failed get comments count for post')
            print('getPostData comments count is: ' + str(count))
            
            # подгружаем только свежие комментарии
            
        comments = self.wallPostService.getComments(self.ownerId, self.postId, commentsOffset)
        results['comments'] = comments
        if offset == kOffsetForPreloadLatestComments:
            results['postData'] = self.postData
        return results
    
    # ObjCBridgeProtocol
    def release(self):
        pass
