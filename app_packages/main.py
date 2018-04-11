from objcbridge import BridgeBase, Subscriber
import vk
from vk import Session
import json
from objc import managers
from threading import Event

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

    def getWall(self):
        session = vk.Session(access_token=storage.accessToken)
        api = vk.API(session)
        api.session.method_default_args['v'] = '5.74'
        response = None
        try:
            response = api.wall.get(access_token=storage.accessToken)
        except Exception as e:
            print('exception: ' + str(e))
            pass
        ownerData = api.users.get(user_id=7162990, fields='photo_100')
        print('ownerData: ' + json.dumps(ownerData))
        return response

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
