from objc import managers
from caches.postsdatabase import PostsDatabase

g_count = 40

class PyImagesViewerViewModel():
    def __init__(self, galleryService, p):
        self.galleryService = galleryService
        self.ownerId = p['ownerId']
        
        postId = p['postId']
        if isinstance(postId, int):
            self.postId = postId
            self.photoIndex = p['photoIndex']
        else:
            self.albumId = p['albumId']
            self.photoId = p['photoId']
    
    def getPhotos(self, offset):
        photosData = None
        if offset == 0:
            photosData = self.galleryService.getAllFromCache(self.ownerId, self.albumId)
        else:
            photosData = self.galleryService.getPhotos(self.ownerId, self.albumId, offset, count=g_count)
        return photosData

    def navigateWithPhotoId(self, photoId):
        managers.shared().screensManager().showDetailPhotoViewControllerWithOwnerId_albumId_photoId_(args=[self.ownerId, self.albumId, photoId])


    def getPostData(self):
        result = {}
        try:
            cache = PostsDatabase()
            data = cache.getById(self.ownerId, self.postId)
            result = data
        except Exception as e:
            print('getPostData imageViewer exception: ' + str(e))
        return result
