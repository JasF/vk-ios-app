from objc import managers
from caches.postsdatabase import PostsDatabase
import json
import threading
from objcbridge import BridgeBase, ObjCBridgeProtocol
import analytics

g_count = 40

class PyImagesViewerViewModelDelegate(BridgeBase):
    pass

class PyImagesViewerViewModel(ObjCBridgeProtocol):
    def __init__(self, galleryService, delegateId, p):
        self.galleryService = galleryService
        self.ownerId = p.get('ownerId')
        self.postId = None
        self.albumId = None
        self.photoIndex = None
        self.messageId = None
        self.withPhotoItems = False
        self.guiDelegate = PyImagesViewerViewModelDelegate(delegateId)
        
        postId = p.get('postId')
        messageId = p.get('messageId')
        if isinstance(messageId, int):
            self.messageId = messageId
            self.photoIndex = p.get('photoIndex')
        if isinstance(postId, int):
            self.postId = postId
            self.photoIndex = p.get('photoIndex')    
        else:
            self.albumId = p.get('albumId')
            self.photoId = p.get('photoId')
    
    def getPhotos(self, offset):
        photosData = None
        if isinstance(self.messageId, int):
            photosData = self.galleryService.photosForMessage(self.messageId)
            return {'items': photosData}
        if offset == 0:
            photosData = self.galleryService.getAllFromCache(self.ownerId, self.albumId)
        else:
            photosData = self.galleryService.getPhotos(self.ownerId, self.albumId, offset, count=g_count)
        return photosData

    def navigateWithPhotoId(self, photoId):
        analytics.log('ImageViewer_segue')
        if isinstance(self.postId, int):
            pass
        managers.shared().screensManager().showDetailPhotoViewControllerWithOwnerId_photoId_(args=[self.ownerId, photoId])


    def getPostData(self):
        result = {}
        try:
            cache = PostsDatabase()
            data = cache.getById(self.ownerId, self.postId)
            result['post_data'] = data
            
            att = data['attachments']
            ids = []
            for d in att:
                if d['type'] == 'photo':
                    ids.append(d['photo']['id'])
            def requestPhotos():
                self.galleryService.getPhotosByIds(self.ownerId, ids)
                self.guiDelegate.photosDataDidUpdatedFromApi()
                #print('photos requested')
            threading.Thread(target=requestPhotos).start()
            
        except Exception as e:
            print('getPostData imageViewer exception: ' + str(e))
        return result

    def release(self):
        pass
