from objc import managers
import vk

class PyMenuViewModel():
    def lentaTapped(self):
        managers.shared().screensManager().showWallViewController()
    
    def newsTapped(self):
        managers.shared().screensManager().showNewsViewController()
    
    def dialogsTapped(self):
        managers.shared().screensManager().showChatListViewController()

    def friendsTapped(self):
        managers.shared().screensManager().showFriendsViewController()

    def photosTapped(self):
        managers.shared().screensManager().showPhotoAlbumsViewController_(args=[vk.userId()])

    def answersTapped(self):
        managers.shared().screensManager().showAnswersViewController()

    def groupsTapped(self):
        managers.shared().screensManager().showGroupsViewController_(args=[vk.userId()])
