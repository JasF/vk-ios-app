import vk
import json
from vk import users
import traceback
from caches.photosdatabase import PhotosDatabase


class GalleryService:
    def __init__(self):
        pass
    
    def getAllFromCache(self, ownerId, albumId):
        api = vk.api()
        items = None
        try:
            cache = PhotosDatabase()
            items = cache.getAll(ownerId, albumId)
            cache.close()
        except Exception as e:
            print('getAllFromCache exception: ' + str(e))
        return {'items': items}
    
    def getPhotos(self, ownerId, albumId, offset, count):
        api = vk.api()
        response = None
        try:
            response = api.photos.get(owner_id=ownerId, album_id=albumId, offset=offset, count=count, extended=1)
            l = response['items']
            #print('photos.get resp: ' + json.dumps(response, indent=4))
            cache = PhotosDatabase()
            cache.update(l)
            cache.close()
        except Exception as e:
            print('getPhotos exception: ' + str(e))
        return response

