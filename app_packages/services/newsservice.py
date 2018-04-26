import vk
import json
import traceback
from vk import users as users
from caches.postsdatabase import PostsDatabase

class NewsService:
    def __init__(self, usersDecorator):
        self.usersDecorator = usersDecorator
    
    def getNews(self, offset, next_from):
        response = None
        usersData = None
        try:
            api = vk.api()
            if isinstance(next_from, str):
                response = api.newsfeed.get(start_from=next_from)
            else:
                response = api.newsfeed.get()
            next_from = response.get('next_from')
            l = response["items"]
            print('news response: ' + json.dumps(l, sort_keys=True, indent=4, separators=(',', ': ')))
            for d in l:
                d['id'] = d.get('post_id') if isinstance(d.get('post_id'), int) else 0
            cache = PostsDatabase()
            cache.update(l)
            cache.close()

            usersData = self.usersDecorator.usersDataFromPosts(l)
        
        except Exception as e:
            print('newsfeed.get exception: ' + str(e))
        results = {'response':response, 'users':usersData}
        return results, next_from

