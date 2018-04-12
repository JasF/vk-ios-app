from objcbridge import BridgeBase, Subscriber
import vk
from vk import Session
import json
from objc import managers
from threading import Event
from caches.users import UsersDatabase

class Storage():
    def __init__(self):
        self.accessToken = ''

storage = Storage()

class AuthorizationHandlerProtocolDelegate(BridgeBase):
    pass

class NewsHandlerProtocolDelegate(BridgeBase):
    pass

class NewsHandlerProtocol:
    def menuTapped(self):
        managers.shared().screensManager().showMenu()

    def getWall(self, offset):
        users = UsersDatabase()
        session = vk.Session(access_token=storage.accessToken)
        api = vk.API(session)
        api.session.method_default_args['v'] = '5.74'
        response = None
        usersData = None
        try:
            response = api.wall.get(access_token=storage.accessToken, offset=offset)
            l = response["items"]
            print('first item is: ' + str(l[0]))
            print('third item is: ' + str(l[2]))
            fromIds = [d['from_id'] for d in l]
            ownerIds = [d['owner_id'] for d in l]
            ids = set()
            ids |= set(fromIds)
            ids |= set(ownerIds)
            usersData = users.getShortUsersByIds(ids)
            #print('localdata: ' + str(usersData))
            fetchedIds = set([d['id'] for d in usersData])
            ids = ids - fetchedIds
            if len(ids):
                idsString = ', '.join(str(e) for e in ids)
                freshUsersData = api.users.get(user_ids=idsString, fields='photo_100')
                users.update(freshUsersData)
                usersData.extend(freshUsersData)
        except Exception as e:
            print('wall.get exception: ' + str(e))
        finally:
            users.close()
        return {'response':response, 'users':usersData}

class MenuHandlerProtocol:
    def newsTapped(self):
        managers.shared().screensManager().showNewsViewController(handler=NewsHandlerProtocol())


class AuthorizationHandlerProtocol:
    def accessTokenGathered(self, aAccessToken):
        storage.accessToken = aAccessToken
        managers.shared().screensManager().showNewsViewController(handler=NewsHandlerProtocol())

def launch():
    Subscriber().setClassHandler(MenuHandlerProtocol())
    managers.shared().screensManager().showAuthorizationViewController(handler=AuthorizationHandlerProtocol())
    pass
