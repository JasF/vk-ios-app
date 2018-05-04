from objc import managers
from services.wallservice import WallService
from objcbridge import BridgeBase, ObjCBridgeProtocol
import vk, json
from vk import users
from caches.photosdatabase import PhotosDatabase

class PyMWPhotoBrowserViewModel(ObjCBridgeProtocol):
    def __init__(self):
        pass
    
    def numberOfCommentsownerId(self, photoId, ownerId):
        result = 0
        try:
            cache = PhotosDatabase()
            items = cache.getPhoto(ownerId, photoId)
            result = items['comments']['count']
            cache.close()
        except Exception as e:
            print('numberOfCommentsownerId exception: ' + str(e))
        return result

    # ObjCBridgeProtocol
    def release(self):
        pass
