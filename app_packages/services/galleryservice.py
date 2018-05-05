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
        response = None
        try:
            api = vk.api()
            response = api.photos.get(owner_id=ownerId, album_id=albumId, offset=offset, count=count, extended=1)
            l = response['items']
            #print('photos.get resp: ' + json.dumps(response, indent=4))
            cache = PhotosDatabase()
            cache.update(l)
            cache.close()
        except Exception as e:
            print('getPhotos exception: ' + str(e))
        return response

    def getPhotosByIds(self, ownerId, ids):
        results = []
        try:
            api = vk.api()
            cache = PhotosDatabase()
            #results = cache.getPhotosByIds(ownerId, ids)
            if len(ids) == len(results):
                print('return cached photos from galleryService:getPhotosByIds')
                return results
        
            fullIds = [str(ownerId) + '_' + str(id) for id in ids]
            results = api.photos.getById(photos=','.join(id for id in fullIds), extended=1)
            
            cache.update(results)
            
            #print('getPhotosByIds result: ' + json.dumps(results, indent=4))
            cache.close()
        except Exception as e:
            print('getPhotosByIds exception: ' + str(e))
        return results
