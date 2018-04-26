import vk
import json
from vk import users
import traceback
from vk import users as users
from caches.videosdatabase import VideosDatabase
from caches.commentsdatabase import CommentsDatabase

g_count = 40

class DetailVideoService:
    def __init__(self, usersDecorator):
        self.usersDecorator = usersDecorator
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
    
    def getComments(self, ownerId, videoId, offset):
        api = vk.api()
        result = None
        try:
            result = api.video.getComments(owner_id=ownerId, video_id=videoId, offset=offset, count=g_count)
            l = result['items']
            '''
                cache = CommentsDatabase()
                cache.update(l)
                cache.close()
                '''
        except Exception as e:
            print('DetailVideo: get comments exception: ' + str(e))
        return result
