import vk
import json
from vk import users as users
from caches.friendsdatabase import FriendsDatabase
from viewmodels.pyfriendsviewmodel import UsersListTypes

g_count = 40

class FriendsService:
    def getFriends(self, userId, offset):
        ids = self.getFriendsIds(userId, offset, UsersListTypes.FRIENDS)
        usersData = users.getShortUsersByIds(set(ids))
        return {'response':usersData}
    
    def getSubscriptions(self, userId, offset):
        ids = self.getFriendsIds(userId, offset, UsersListTypes.SUBSCRIPTIONS)
        usersData = users.getShortUsersByIds(set(ids))
        print('getSubscriptions response: ' + str(usersData))
        return {'response':usersData}

    def getFollowers(self, userId, offset):
        ids = self.getFriendsIds(userId, offset, UsersListTypes.FOLLOWERS)
        usersData = users.getShortUsersByIds(set(ids))
        print('FOLLOWERS response: ' + str(usersData))
        return {'response':usersData}

    def getFriendsIds(self, userId, offset, usersListType):
        api = vk.api()
        try:
            friendsArray = []
            db = FriendsDatabase()
            if usersListType == UsersListTypes.FRIENDS:
                friendsArray = db.getFriendsIds(userId, offset, g_count)
                if not friendsArray:
                    friendsArray = []

            if len(friendsArray) >= g_count:
                result = [d.get('id') for d in friendsArray]
                print('results from db: ' + str(len(result)))
                return result
            if usersListType == UsersListTypes.SUBSCRIPTIONS:
                print('usersListType offset: ' + str(offset))
                response = api.users.getSubscriptions(user_id=userId, extended=1, offset=offset, count=g_count)
            elif usersListType == UsersListTypes.FOLLOWERS:
                response = api.users.getFollowers(user_id=userId, offset=offset, count=g_count)
            else:
                response = api.friends.get(offset=offset, count=g_count, order='hints', user_id=userId)
            l = response['items']
            if usersListType == UsersListTypes.SUBSCRIPTIONS:
                ar = []
                for d in l:
                    if d.get('type') == 'page':
                        ar.append(-d.get('id'))
                    elif d.get('type') == 'profile':
                        ar.append(d.get('id'))
                l = ar
                print('usersListType l: ' + str(l))
            count = response['count']
            if usersListType == UsersListTypes.FRIENDS:
                db.appendFriendsIds(l)

            db.close()
            return l
        except Exception as e:
            print('getFriendsIds exception: ' + str(e))
        return []

