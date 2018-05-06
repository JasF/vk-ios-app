import vk
import json
import traceback
from vk import users as users
from caches.postsdatabase import PostsDatabase
from caches.usersdatabase import UsersDatabase
import time, threading
from postproc import textpatcher

class WallService:
    def __init__(self, userId, usersDecorator):
        self.userInfo = None
        self.usersDecorator = usersDecorator
        self.userId = userId
        if self.userId == None or self.userId == 0:
            self.userId = vk.userId()
    
    def getWall(self, offset, userId, count):
        print('getWall userId: ' + str(userId))
        response = None
        usersData = None
        try:
            api = vk.api()
            forceResponse = api.captcha.force()
            print('forceResponse for captch: ' + str(forceResponse))
            
            response = api.wall.get(offset=offset, owner_id=userId, count=count)
            textpatcher.cropTagsOnPostsResults(response)
            l = response["items"]
            #print('wall response: ' + json.dumps(l, indent=4))
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
                self.userInfo = usersInfo[0]
        return self.userInfo

    def getBigUserInfo(self):
        if self.userInfo == None:
            userInfo = users.getBigUserById(self.userId)
            if userInfo:
                print('set userInfo may be slowly on poor connection and startup breaking')
                self.userInfo = userInfo
        if self.userInfo and vk.userId() == self.userId:
                self.userInfo['currentUser'] = 1
        return self.userInfo

        thread = threading.Thread(target=perform)
        thread.start()
