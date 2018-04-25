from objc import managers
from services.wallservice import WallService
from objcbridge import BridgeBase, ObjCBridgeProtocol
import vk, json

# https://vk.com/dev/wall.getComments
class PyDetailPhotoViewModel():
    def __init__(self, detailPhotoService, ownerId, albumId, photoId):
        self.detailPhotoService = detailPhotoService
        self.ownerId = ownerId
        self.albumId = albumId
        self.photoId = photoId
        print('PyDetailPhotoViewModel ownerId: ' + str(ownerId) + '; albumId: '+ str(albumId) + ' ' + str(photoId))
        self.photoData = None
    
    # protocol methods implementation
    def getPhotoData(self, offset):
        results = {}
        if not self.photoData:
            #self.photoData = self.detailPhotoService.getPostById(self.postId)
            comments = self.detailPhotoService.getComments(self.ownerId, self.photoId, offset)
            print('comments: ' + str(comments))
            results['comments'] = comments
        if offset == 0:
            results['photoData'] = self.photoData
        return results
    
    # ObjCBridgeProtocol
    def release(self):
        pass
