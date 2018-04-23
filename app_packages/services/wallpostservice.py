import vk
import json
from vk import users
import traceback
from vk import users as users
from caches.postsdatabase import PostsDatabase
from caches.commentsdatabase import CommentsDatabase

g_count = 40

class WallPostService:
    def __init__(self, usersDecorator):
        self.usersDecorator = usersDecorator
        pass

    def getPostById(self, identifier):
        response = None
        usersData = None
        l = None
        try:
            cache = PostsDatabase()
            result = cache.getById(identifier)
            cache.close()
            if not result:
                return None
            l = [result]
            usersData = self.usersDecorator.usersDataFromPosts(l)
        
        except Exception as e:
            print('wall post service exception: ' + str(e))
        results = {'response':{'items':l}, 'users':usersData}
        return results
        
        return result

    def getComments(self, ownerId, postId, offset):
        api = vk.api()
        result = None
        try:
            result = api.wall.getComments(owner_id=ownerId, post_id=postId, offset=offset, count=g_count)
            l = result['items']
            cache = CommentsDatabase()
            cache.update(l)
            cache.close()
        
        except Exception as e:
            print('get comments exception: ' + str(e))
        return result
