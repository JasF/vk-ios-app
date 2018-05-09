from objc import managers
from services.wallservice import WallService
from objcbridge import BridgeBase, ObjCBridgeProtocol
import vk, json
from vk import users
from constants import g_CommentsCount

kOffsetForPreloadLatestComments = -1
class PyDetailPhotoViewModel():
    def __init__(self, detailPhotoService, ownerId, photoId):
        self.detailPhotoService = detailPhotoService
        self.ownerId = ownerId
        self.photoId = photoId
        #print('PyDetailPhotoViewModel ownerId: ' + str(ownerId) + ' ' + str(photoId))
        self.photoData = None
        self.userInfo = None
    
    # protocol methods implementation
    def getPhotoData(self, offset):
        results = {}
        commentsOffset = offset
        if not self.photoData:
            self.userInfo = users.getShortUserById(self.ownerId)
            print('self.userInfo for ' + str(self.ownerId) + ' is ' + json.dumps(self.userInfo, indent=4))
            self.photoData = self.detailPhotoService.getPhoto(self.ownerId, self.photoId)
            if offset == kOffsetForPreloadLatestComments:
                commentsOffset = 0
                count = 0
                try:
                    count = self.photoData['comments']['count']
                    commentsOffset = count - g_CommentsCount
                    if commentsOffset < 0:
                        commentsOffset = 0
                except:
                    print('failed get comments count for photo')
            comments = self.detailPhotoService.getComments(self.ownerId, abs(self.photoId), commentsOffset, g_CommentsCount)
            results['comments'] = comments
    
        self.photoData['owner'] = self.userInfo
        results['photoData'] = self.photoData
        return results
    
    # ObjCBridgeProtocol
    def release(self):
        pass
