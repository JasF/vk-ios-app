from objc import managers

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
        #managers.shared().screensManager().showDetailPhotoViewControllerWithOwnerId_albumId_photoId_(args=[self.ownerId, self.albumId, photoId])
        managers.shared().screensManager().showImagesViewerViewControllerWithOwnerId_albumId_photoId_(args=[self.ownerId, self.albumId, photoId])

