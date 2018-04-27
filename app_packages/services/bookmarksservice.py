import vk
import json
import traceback
from vk import users as users
from caches.postsdatabase import PostsDatabase

class BookmarksService:
    def __init__(self, usersDecorator):
        self.usersDecorator = usersDecorator
        pass
    
    def getBookmarks(self, offset):
        api = vk.api()
        response = None
        usersData = None
        count = 0
        try:
            print('api.fave.getPosts offset: ' + str(offset))
            response = api.fave.getPosts(offset=offset)
            l = response['items']
            count = len(l)
            usersData = self.usersDecorator.usersDataFromPosts(l)
        except Exception as e:
            print('getBookmarks exception: ' + str(e))
        return {'response': response, 'users': usersData}, count
