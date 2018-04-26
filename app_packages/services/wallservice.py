import vk
import json
import traceback
from vk import users as users
from caches.postsdatabase import PostsDatabase

class WallService:
    def __init__(self, userId, usersDecorator):
        self.userInfo = None
        self.usersDecorator = usersDecorator
        self.userId = userId
        if self.userId == None or self.userId == 0:
            self.userId = vk.userId()
    
    def getWall(self, offset, userId):
        response = None
        usersData = None
        try:
            api = vk.api()
            response = api.wall.get(offset=offset, owner_id=userId)
            l = response["items"]
            
            print('wall response: ' + json.dumps(l, sort_keys=True, indent=4, separators=(',', ': ')))
            cache = PostsDatabase()
            cache.update(l)
            cache.close()
            
            usersData = self.usersDecorator.usersDataFromPosts(l)
            
        except Exception as e:
            print('wall.get exception: ' + str(e))
        results = {'response':response, 'users':usersData}
        return results
    
    # private
    def getUserInfo(self):
        if self.userInfo == None:
            usersInfo = users.getShortUsersByIds(set([self.userId]))
            if len(usersInfo) > 0:
                print('set userInfo may be slowly on poor connection and startup breaking')
                self.userInfo = usersInfo[0]
        return self.userInfo
