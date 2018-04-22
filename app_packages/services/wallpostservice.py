import vk
import json
from vk import users
import traceback
from vk import users as users
from caches.postsdatabase import PostsDatabase


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
