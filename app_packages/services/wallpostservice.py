import vk, os, sys
import json
from vk import users
import traceback
from vk import users as users
from caches.postsdatabase import PostsDatabase
from caches.commentsdatabase import CommentsDatabase


class WallPostService:
    def __init__(self, usersDecorator):
        self.usersDecorator = usersDecorator
        pass

    def getPostById(self, ownerId, postId):
        response = None
        usersData = None
        l = None
        try:
            cache = PostsDatabase()
            result = cache.getById(ownerId, postId)
            cache.close()
            if not result:
                return None
            l = [result]
            usersData = self.usersDecorator.usersDataFromPosts(l)
        
        except Exception as e:
            exc_type, exc_obj, exc_tb = sys.exc_info()
            fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
            print(exc_type, fname, exc_tb.tb_lineno)
            print('wall post service exception: ' + str(e))
            print(traceback.format_exc())
        results = {'response':{'items':l}, 'users':usersData}
        return results
        
        return result

    def getComments(self, ownerId, postId, offset, count):
        api = vk.api()
        result = None
        try:
            result = api.wall.getComments(owner_id=ownerId, post_id=postId, offset=offset, count=count, need_likes=1, extended=1)
            l = result['items']
            print('wall.getComments : ' + json.dumps(result, indent=4))
            cache = CommentsDatabase()
            cache.update(l)
            cache.close()
        
        except Exception as e:
            print('WallPost: get comments exception: ' + str(e))
        return result
