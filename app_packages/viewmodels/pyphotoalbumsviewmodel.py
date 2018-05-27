from objc import managers
from services.wallservice import WallService
from objcbridge import BridgeBase, ObjCBridgeProtocol
import vk, json, analytics
from requests.exceptions import ConnectionError

class PyPhotoAlbumsViewModel():
    def __init__(self, photoAlbumsService, ownerId):
        self.photoAlbumsService = photoAlbumsService
        self.ownerId = ownerId
        print('PyPhotoAlbumsViewModel ownerId: ' + str(ownerId))
    
    def getPhotoAlbums(self, offset):
        try:
            albumsData = self.photoAlbumsService.getPhotoAlbums(self.ownerId, offset)
        except ConnectionError as e:
            return {'error':{'type':'connection'}}
        return albumsData

    def menuTapped(self):
        managers.shared().screensManager().showMenu()

    def tappedOnAlbumWithId(self, albumId):
        analytics.log('PhotoAlbum_segue')
        managers.shared().screensManager().showGalleryViewControllerWithOwnerId_albumId_(args=[self.ownerId, albumId]);
