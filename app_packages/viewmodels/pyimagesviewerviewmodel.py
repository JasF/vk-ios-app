from objc import managers
from caches.postsdatabase import PostsDatabase
import json

g_count = 40

class PyImagesViewerViewModel():
    def __init__(self, galleryService, p):
        self.galleryService = galleryService
        self.ownerId = p.get('ownerId')
        self.postId = None
        self.albumId = None
        self.photoIndex = None
        
        postId = p.get('postId')
        if isinstance(postId, int):
            self.postId = postId
            self.photoIndex = p.get('photoIndex')
        else:
            self.albumId = p.get('albumId')
            self.photoId = p.get('photoId')
    
    def getPhotos(self, offset):
        photosData = None
        if offset == 0:
            photosData = self.galleryService.getAllFromCache(self.ownerId, self.albumId)
        else:
            photosData = self.galleryService.getPhotos(self.ownerId, self.albumId, offset, count=g_count)
        return photosData

    def navigateWithPhotoId(self, photoId):
        if isinstance(self.postId, int):
            pass
        managers.shared().screensManager().showDetailPhotoViewControllerWithOwnerId_albumId_photoId_(args=[self.ownerId, self.albumId, photoId])


    def getPostData(self):
        result = {}
        try:
            cache = PostsDatabase()
            data = cache.getById(self.ownerId, self.postId)
            #result['post_data'] = data
            
            att = data['attachments']
            ids = []
            for d in att:
                if d['type'] == 'photo':
                    ids.append(d['photo']['id'])
        
            photosData = self.galleryService.getPhotosByIds(self.ownerId, ids)
            result['images_data'] = {'items':photosData}
        except Exception as e:
            print('getPostData imageViewer exception: ' + str(e))
        return result
