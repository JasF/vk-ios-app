import vk
import json
from vk import users as users
from caches.friendsdatabase import FriendsDatabase

g_count = 40

class FriendsService:
    def getFriends(self, userId, offset):
        ids = self.getFriendsIds(userId, offset)
        usersData = users.getShortUsersByIds(set(ids))
        return {'response':usersData}

    def getFriendsIds(self, userId, offset):
        api = vk.api()
        try:
            db = FriendsDatabase()
            friendsArray = db.getFriendsIds(userId, offset, g_count)
            if not friendsArray:
                friendsArray = []

            if len(friendsArray) >= g_count:
                result = [d.get('id') for d in friendsArray]
                print('results from db: ' + str(len(result)))
                return result

            response = api.friends.get(offset=offset, count=g_count, order='hints', user_id=userId)
            l = response['items']
            count = response['count']
            db.appendFriendsIds(l)
            #print('response FriendsService: ' + str(response))
            #ids = set([d['message']['user_id'] for d in l])
            #usersData = users.getShortUsersByIds(ids)

            db.close()
            return l
        except Exception as e:
            print('getFriendsIds exception: ' + str(e))
        return []

