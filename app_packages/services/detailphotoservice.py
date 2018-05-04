import vk
import json
from vk import users
import traceback
from vk import users as users
from caches.photosdatabase import PhotosDatabase
from caches.commentsdatabase import CommentsDatabase

class DetailPhotoService:
    def __init__(self, usersDecorator, commentsService):
        self.usersDecorator = usersDecorator
        self.commentsService = commentsService
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
        result = self.commentsService.getPhotoComments(ownerId, photoId, offset, count)
        return result

    def sendComment(self, ownerId, postId, messsage, reply_to_comment=0):
        result = None
        try:
            api = vk.api()
            result = api.photos.createComment(owner_id=ownerId, photo_id=postId, message=messsage, reply_to_comment=reply_to_comment)
        except Exception as e:
            print('DetailPhotoService: sendComment exception: ' + str(e))
        return result
