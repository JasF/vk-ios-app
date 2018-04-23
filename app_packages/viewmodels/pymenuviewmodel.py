from objc import managers
import vk

class PyMenuViewModel():
    def newsTapped(self):
        managers.shared().screensManager().showWallViewController()
    
    def dialogsTapped(self):
        managers.shared().screensManager().showChatListViewController()

    def friendsTapped(self):
        managers.shared().screensManager().showFriendsViewController()

    def photosTapped(self):
        managers.shared().screensManager().showPhotoAlbumsViewController_(args=[vk.userId()])
