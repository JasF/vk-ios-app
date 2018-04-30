from objc import managers
from objcbridge import BridgeBase, ObjCBridgeProtocol
import vk
from .pyfriendsviewmodel import UsersListTypes

class PyAuthorizationViewModel(ObjCBridgeProtocol):
    # protocol methods implementation
    def accessTokenGathereduserId(self, aAccessToken, aUserId):
        vk.setToken(aAccessToken)
        vk.setUserId(aUserId)
        managers.shared().screensManager().showFriendsViewController_usersListType_(args=[vk.userId(), UsersListTypes.FRIENDS])
        #managers.shared().screensManager().showChatListViewController()
        #managers.shared().screensManager().showWallViewController()
        #managers.shared().screensManager().showWallViewController_(args=[82108968])
        #managers.shared().screensManager().showPhotoAlbumsViewController_(args=[vk.userId()])
        #managers.shared().screensManager().showNewsViewController()
        #managers.shared().screensManager().showAnswersViewController()
        #managers.shared().screensManager().showGroupsViewController_(args=[vk.userId()])
        #managers.shared().screensManager().showBookmarksViewController()
        #managers.shared().screensManager().showVideosViewController_(args=[vk.userId()])
        #managers.shared().screensManager().showDocumentsViewController_(args=[vk.userId()])
        #managers.shared().screensManager().showSettingsViewController()
    
    # ObjCBridgeProtocol
    def release(self):
        pass
