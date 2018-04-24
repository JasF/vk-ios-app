import vk
import json
import traceback
from vk import users as users
from caches.postsdatabase import PostsDatabase

class NewsService:
    def __init__(self, usersDecorator):
        self.usersDecorator = usersDecorator
    
    def getNews(self, offset):
        response = None
        usersData = None
        try:
            api = vk.api()
            response = api.newsfeed.get()
            l = response["items"]
            print('newsfeed: ' + json.dumps(response))
            
            '''
            cache = PostsDatabase()
            cache.update(l)
            cache.close()
            '''
            
            usersData = self.usersDecorator.usersDataFromPosts(l)
        
        except Exception as e:
            print('newsfeed.get exception: ' + str(e))
        results = {'response':response, 'users':usersData}
        return results

