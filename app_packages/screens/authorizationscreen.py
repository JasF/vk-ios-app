from objc import managers
import vk

class AuthorizationHandlerProtocol:
    def accessTokenGathereduserId(self, aAccessToken, aUserId):
        vk.setToken(aAccessToken)
        vk.setUserId(aUserId)
        #managers.shared().screensManager().showFriendsViewController()
        #managers.shared().screensManager().showChatListViewController()
        #managers.shared().screensManager().showWallViewController()
        #managers.shared().screensManager().showPhotoAlbumsViewController_(args=[vk.userId()])
        managers.shared().screensManager().showNewsViewController()
