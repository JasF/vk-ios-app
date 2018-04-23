from objc import managers
from services.wallservice import WallService
from objcbridge import BridgeBase, ObjCBridgeProtocol
import vk, json

class PyPhotoAlbumsViewModel():
    def __init__(self, photoAlbumsService, ownerId):
        self.photoAlbumsService = photoAlbumsService
        self.ownerId = ownerId
        print('PyPhotoAlbumsViewModel ownerId: ' + str(ownerId))
    
    def getPhotoAlbums(self, offset):
        albumsData = self.photoAlbumsService.getPhotoAlbums(self.ownerId, offset)
        return albumsData

    def menuTapped(self):
        managers.shared().screensManager().showMenu()
