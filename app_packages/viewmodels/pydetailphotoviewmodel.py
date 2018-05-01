from objc import managers
from services.wallservice import WallService
from objcbridge import BridgeBase, ObjCBridgeProtocol
import vk, json
from vk import users
from constants import g_CommentsCount

class PyDetailPhotoViewModel():
    def __init__(self, detailPhotoService, ownerId, albumId, photoId):
        self.detailPhotoService = detailPhotoService
        self.ownerId = ownerId
        self.albumId = albumId
        self.photoId = photoId
        print('PyDetailPhotoViewModel ownerId: ' + str(ownerId) + '; albumId: '+ str(albumId) + ' ' + str(photoId))
        self.photoData = None
        self.userInfo = None
    
    # protocol methods implementation
    def getPhotoData(self, offset):
        results = {}
        if not self.photoData:
            self.userInfo = users.getShortUserById(self.ownerId)
            
            self.photoData = self.detailPhotoService.getPhoto(self.ownerId, self.photoId)
            comments = self.detailPhotoService.getComments(self.ownerId, self.photoId, offset, g_CommentsCount)
            results['comments'] = comments
        if offset == 0:
            self.photoData['owner'] = self.userInfo
            results['photoData'] = self.photoData
        return results
    
    # ObjCBridgeProtocol
    def release(self):
        pass
