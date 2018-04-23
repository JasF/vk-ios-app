import vk
import json
from vk import users
import traceback
from caches.photoalbumsdatabase import PhotoAlbumsDatabase

g_count = 40

class GalleryService:
    def __init__(self):
        pass
    
    def getPhotos(self, ownerId, albumId, offset):
        api = vk.api()
        response = None
        try:
            response = api.photos.get(owner_id=ownerId, album_id=albumId, offset=offset, count=g_count, extended=1)
            l = response['items']
            #cache = PhotosDatabase()
            #cache.update(l)
            #cache.close()
        except Exception as e:
            print('getPhotos exception: ' + str(e))
        return response

