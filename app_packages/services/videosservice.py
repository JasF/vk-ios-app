import vk
import json
import traceback
from vk import users as users
from caches.videosdatabase import VideosDatabase

class VideosService:
    def __init__(self):
        pass
    
    def getVideos(self, ownerId, offset):
        api = vk.api()
        response = None
        count = 0
        try:
            response = api.video.get(owner_id=ownerId, offset=offset)
            l = response['items']
            count = len(l)
            
            cache = VideosDatabase()
            cache.update(l)
            cache.close()
        except Exception as e:
            print('getVideos exception: ' + str(e))
        return {'response': response}, count

