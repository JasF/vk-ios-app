import vk
import json
from vk import users
import traceback
from vk import users as users
from caches.videosdatabase import VideosDatabase
from caches.commentsdatabase import CommentsDatabase
from postproc import textpatcher

class DetailVideoService:
    def __init__(self, usersDecorator, commentsService):
        self.usersDecorator = usersDecorator
        self.commentsService = commentsService
        pass
    
    def getVideo(self, ownerId, videoId):
        items = None
        try:
            cache = VideosDatabase()
            items = cache.getVideo(ownerId, videoId)
            #print('single video: ' + str(items) + ' for: ' + str(ownerId) + ' ; videoId: ' + str(videoId))
            cache.close()
        except Exception as e:
            print('DetailVideoService getVideo exception: ' + str(e))
        return items
    
    def getComments(self, ownerId, videoId, offset, count):
        result = self.commentsService.getVideoComments(ownerId, videoId, offset, count)
        return result

    def updateVideo(self, ownerId, videoId):
        result = {}
        try:
            api = vk.api()
            result = api.video.get(videos=str(ownerId) + '_' + str(videoId), extended=1)
            textpatcher.cropTagsInResults(result, 'description')
            items = result['items']
            cache = VideosDatabase()
            cache.update(items)
            cache.close()
            representation = items[0]
            if isinstance(representation, dict):
                result = representation
        except Exception as e:
            print('DetailVideoService: updateVideo exception: ' + str(e))
        return result
    
    def sendComment(self, ownerId, postId, messsage, reply_to_comment=0):
        result = None
        try:
            api = vk.api()
            result = api.video.createComment(owner_id=ownerId, video_id=postId, message=messsage, reply_to_comment=reply_to_comment)
        except Exception as e:
            print('DetailVideoService: sendComment exception: ' + str(e))
        return result
