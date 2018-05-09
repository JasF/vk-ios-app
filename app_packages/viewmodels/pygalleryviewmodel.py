from objc import managers
import analytics

g_count = 40

class PyGalleryViewModel():
    def __init__(self, galleryService, ownerId, albumId):
        self.galleryService = galleryService
        self.ownerId = ownerId
        self.albumId = albumId
        print('PyGalleryViewModel ownerId: ' + str(ownerId) + '; albumId: ' + str(albumId))
    
    def getPhotos(self, offset):
        photosData = self.galleryService.getPhotos(self.ownerId, self.albumId, offset, count=g_count)
        return photosData

    def tappedOnPhotoWithId(self, photoId):
        analytics.log('Gallery_segue')
        managers.shared().screensManager().showImagesViewerViewControllerWithOwnerId_albumId_photoId_(args=[self.ownerId, self.albumId, photoId])

