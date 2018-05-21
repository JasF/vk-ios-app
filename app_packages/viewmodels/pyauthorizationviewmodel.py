from objc import managers
from objcbridge import BridgeBase, ObjCBridgeProtocol
import vk, screenshow, settings
from .pyfriendsviewmodel import UsersListTypes

class PyAuthorizationViewModel(ObjCBridgeProtocol):
    # protocol methods implementation
    def accessTokenGathereduserId(self, aAccessToken, aUserId):
        settings.set('access_token', aAccessToken)
        settings.set('user_id', aUserId)
        settings.write()
        vk.setToken(aAccessToken)
        vk.setUserId(aUserId)
        screenshow.showScreenAfterAuthorization()
    
    def showEula(self):
        managers.shared().screensManager().showEulaViewController()
    
    # ObjCBridgeProtocol
    def release(self):
        pass
