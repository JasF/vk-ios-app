from objcbridge import BridgeBase, Subscriber
import vk
from vk import Session
import json
from objc import managers
from threading import Event

class AuthorizationHandlerProtocolDelegate(BridgeBase):
    pass

class NewsHandlerProtocolDelegate(BridgeBase):
    pass

class NewsHandlerProtocol:
    def menuTapped(self):
        managers.shared().screensManager().showMenu()

class MenuHandlerProtocol:
    def newsTapped(self):
        managers.shared().screensManager().showNewsViewController(handler=NewsHandlerProtocol())

class AuthorizationHandlerProtocol:
    def accessTokenGathered(self, accessToken):
        print('accesstoken: ' + accessToken)
        managers.shared().screensManager().showNewsViewController(handler=NewsHandlerProtocol())
        '''
        session = vk.Session(access_token=accessToken)
        api = vk.API(session)
        api.session.method_default_args['v'] = '5.74'
        response = api.wall.get(access_token=accessToken)
        self.event = Event()
        result = AuthorizationHandlerProtocol().receivedWall_(handler=self, args=[response], withResult=True)
        '''

def launch():
    Subscriber().setClassHandler(MenuHandlerProtocol())
    managers.shared().screensManager().showAuthorizationViewController(handler=AuthorizationHandlerProtocol())
    pass
