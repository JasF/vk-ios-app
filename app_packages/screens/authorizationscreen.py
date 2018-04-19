from objc import managers
import vk

class AuthorizationHandlerProtocol:
    def accessTokenGathereduserId(self, aAccessToken, aUserId):
        vk.setToken(aAccessToken)
        vk.setUserId(aUserId)
        managers.shared().screensManager().showChatListViewController()
        #managers.shared().screensManager().showWallViewController()
