import vk
import json
from vk import users
import traceback
from vk import users as users
from caches.videosdatabase import VideosDatabase
from caches.commentsdatabase import CommentsDatabase

class DetailVideoService:
    def __init__(self, usersDecorator, commentsService):
        self.usersDecorator = usersDecorator
        self.commentsService = commentsService
        pass
    
    def getVideo(self, ownerId, videoId):
        api = vk.api()
        items = None
        try:
            cache = VideosDatabase()
            items = cache.getVideo(ownerId, videoId)
            print('single video: ' + str(items))
            cache.close()
        except Exception as e:
            print('DetailVideoService getVideo exception: ' + str(e))
        return items
    
    def getComments(self, ownerId, videoId, offset, count):
        result = self.commentsService.getVideoComments(ownerId, videoId, offset, count)
        return result
