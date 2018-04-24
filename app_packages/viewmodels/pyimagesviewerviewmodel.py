from objc import managers

g_count = 40

class PyImagesViewerViewModel():
    def __init__(self, galleryService, ownerId, albumId, photoId):
        self.galleryService = galleryService
        self.ownerId = ownerId
        self.albumId = albumId
        self.photoId = photoId
    
    def getPhotos(self, offset):
        photosData = None
        if offset == 0:
            photosData = self.galleryService.getAllFromCache(self.ownerId, self.albumId)
        else:
            photosData = self.galleryService.getPhotos(self.ownerId, self.albumId, offset, count=g_count)
        return photosData

