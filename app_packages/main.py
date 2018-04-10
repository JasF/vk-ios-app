from objcbridge import BridgeBase
import vk
from vk import Session
import json
from objc import managers
from threading import Event

class AuthorizationHandlerProtocol(BridgeBase):
    pass


class AuthorizationHandlerProtocolDelegate:
    def accessTokenGathered(self, accessToken):
        print('accesstoken: ' + accessToken)
        session = vk.Session(access_token=accessToken)
        api = vk.API(session)
        api.session.method_default_args['v'] = '5.74'
        response = api.wall.get(access_token=accessToken)
        self.event = Event()
        result = AuthorizationHandlerProtocol().receivedWall_(handler=self, args=[response], withResult=True)

def launch():
    screensManager = managers.shared().screensManager().showAuthorizationViewController(handler=AuthorizationHandlerProtocolDelegate())
    pass
