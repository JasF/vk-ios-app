import vk
import json
from vk import users
import traceback
from vk import users as users
from caches.photosdatabase import PhotosDatabase
from caches.commentsdatabase import CommentsDatabase

class DetailPhotoService:
    def __init__(self, usersDecorator):
        self.usersDecorator = usersDecorator
        pass
    
    def getPhoto(self, ownerId, photoId):
        api = vk.api()
        items = None
        try:
            cache = PhotosDatabase()
            items = cache.getPhoto(ownerId, photoId)
            cache.close()
        except Exception as e:
            print('DetailPhotoService getPhoto exception: ' + str(e))
        return items

    def getComments(self, ownerId, photoId, offset, count):
        api = vk.api()
        result = None
        try:
            result = api.photos.getComments(owner_id=ownerId, photo_id=photoId, offset=offset, count=count)
            l = result['items']
            '''
            cache = CommentsDatabase()
            cache.update(l)
            cache.close()
                '''
        except Exception as e:
            print('DetailPhoto: get comments exception: ' + str(e))
        return result
