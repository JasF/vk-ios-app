import vk
import json
from vk import users as users
from caches.friendsdatabase import FriendsDatabase

g_count = 40

class FriendsService:
    def getFriends(self, userId, offset):
        ids = self.getFriendsIds(userId, offset, False)
        usersData = users.getShortUsersByIds(set(ids))
        return {'response':usersData}
    
    def getSubscriptions(self, userId, offset):
        ids = self.getFriendsIds(userId, offset, True)
        usersData = users.getShortUsersByIds(set(ids))
        print('getSubscriptions response: ' + str(usersData))
        return {'response':usersData}

    def getFriendsIds(self, userId, offset, subscriptions):
        api = vk.api()
        try:
            friendsArray = []
            db = FriendsDatabase()
            if not subscriptions:
                friendsArray = db.getFriendsIds(userId, offset, g_count)
                if not friendsArray:
                    friendsArray = []

            if len(friendsArray) >= g_count:
                result = [d.get('id') for d in friendsArray]
                print('results from db: ' + str(len(result)))
                return result
            if subscriptions:
                print('subscriptions offset: ' + str(offset))
                response = api.users.getSubscriptions(user_id=userId, extended=1, offset=offset, count=g_count)
            else:
                response = api.friends.get(offset=offset, count=g_count, order='hints', user_id=userId)
            l = response['items']
            if subscriptions:
                ar = []
                for d in l:
                    if d.get('type') == 'page':
                        ar.append(-d.get('id'))
                    elif d.get('type') == 'profile':
                        ar.append(d.get('id'))
                l = ar
                print('subscriptions l: ' + str(l))
            count = response['count']
            if not subscriptions:
                db.appendFriendsIds(l)
            #print('response FriendsService: ' + str(response))
            #ids = set([d['message']['user_id'] for d in l])
            #usersData = users.getShortUsersByIds(ids)

            db.close()
            return l
        except Exception as e:
            print('getFriendsIds exception: ' + str(e))
        return []

