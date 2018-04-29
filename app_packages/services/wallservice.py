import vk
import json
import traceback
from vk import users as users
from caches.postsdatabase import PostsDatabase
from caches.usersdatabase import UsersDatabase
import time, threading

class WallService:
    def __init__(self, userId, usersDecorator):
        self.userInfo = None
        self.usersDecorator = usersDecorator
        self.userId = userId
        if self.userId == None or self.userId == 0:
            self.userId = vk.userId()
    
    def getWall(self, offset, userId):
        print('getWall userId: ' + str(userId))
        response = None
        usersData = None
        try:
            api = vk.api()
            response = api.wall.get(offset=offset, owner_id=userId)
            l = response["items"]
            #print('wall response: ' + json.dumps(l, sort_keys=True, indent=4, separators=(',', ': ')))
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
            usersInfo = users.getBigUsersByIds(set([self.userId]))
            if len(usersInfo) > 0:
                print('set userInfo may be slowly on poor connection and startup breaking')
                self.userInfo = usersInfo[0]
        if self.userInfo and vk.userId() == self.userId:
                self.userInfo['currentUser'] = 1
        return self.userInfo

    def updateCounters(self, friendsCount, photosCount, videoCount, groupsCount, subscriptionsCount):
        def perform():
            try:
                def safeSet(s, d, k, cb):
                    v = s.get('count')
                    print('k: ' + str(k) + ' v: ' + str(v))
                    d[k] = v if v else 0
                    cb(v if v else 0)
                api = vk.api()
                friendsResponse = api.friends.get(user_id=self.userId, count=1)
                safeSet(friendsResponse, self.userInfo, 'friends_count', friendsCount)
                time.sleep(1)
                photosResponse = api.photos.getAll(owner_id=self.userId, count=0)
                safeSet(photosResponse, self.userInfo, 'photos_count', photosCount)
                time.sleep(1)
                videoResponse = api.video.get(owner_id=self.userId, count=0)
                safeSet(videoResponse, self.userInfo, 'videos_count', videoCount)
                time.sleep(1)
                usersListTypeResponse = api.users.getSubscriptions(user_id=self.userId, extended=1, count=0)
                safeSet(usersListTypeResponse, self.userInfo, 'usersListType_count', subscriptionsCount)
                time.sleep(1)
                groups = api.groups.get(user_id=self.userId, count=0)
                safeSet(groups, self.userInfo, 'groups_count', groupsCount)
                cache = UsersDatabase()
                cache.update([self.userInfo])
            except Exception as e:
                print('updateCounters exception: ' + str(e))
                print(traceback.format_exc())

        thread = threading.Thread(target=perform)
        thread.start()
