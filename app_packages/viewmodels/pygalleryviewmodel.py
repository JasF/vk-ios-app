from objc import managers
from services.wallservice import WallService
from objcbridge import BridgeBase, ObjCBridgeProtocol
import vk, json

class PyGalleryViewModel():
    def __init__(self, galleryService, ownerId, albumId):
        self.galleryService = galleryService
        self.ownerId = ownerId
        self.albumId = albumId
        print('PyGalleryViewModel ownerId: ' + str(ownerId) + '; albumId: ' + str(albumId))
    
    def getPhotos(self, offset):
        photosData = self.galleryService.getPhotos(self.ownerId, self.albumId, offset)
        print('photosData: ' + json.dumps(photosData))
        return photosData
    
    def menuTapped(self):
        managers.shared().screensManager().showMenu()
