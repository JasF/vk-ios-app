import vk
import json
import traceback
from vk import users as users
from caches.postsdatabase import PostsDatabase
from postproc import textpatcher

class NewsService:
    def __init__(self, usersDecorator):
        self.usersDecorator = usersDecorator
    
    def getNews(self, offset, next_from):
        response = None
        usersData = None
        try:
            allowed = ['post']
            api = vk.api()
            if isinstance(next_from, str):
                response = api.newsfeed.get(start_from=next_from,filters=','.join(allowed))
            else:
                response = api.newsfeed.get()
            textpatcher.cropTagsOnPostsResults(response)
            next_from = response.get('next_from')
            rawl = response["items"]
            ids = set()
            l = []
            for d in rawl:
                postid = d.get('post_id')
                if d.get('type') in allowed and isinstance(postid, int):
                    if postid not in ids:
                        ids.add(postid)
                        l.append(d)
            if isinstance(response, dict):
                response['items'] = l
            if len(l) == 0:
                print('response is: ' + json.dumps(response, indent=4))
            print('l response: ' + json.dumps(l, sort_keys=True, indent=4, separators=(',', ': ')))
            '''
            ids = [d['post_id'] for d in l if isinstance(d.get('post_id'), int) == True]
            print('ids: ' + json.dumps(ids, indent=4))
            print('news response: ' + json.dumps(l, sort_keys=True, indent=4, separators=(',', ': ')))
            '''
            cache = PostsDatabase()
            cache.update(l)
            cache.close()

            usersData = self.usersDecorator.usersDataFromPosts(l)
        
        except Exception as e:
            print('newsfeed.get exception: ' + str(e))
        results = {'response':response, 'users':usersData}
        return results, next_from

