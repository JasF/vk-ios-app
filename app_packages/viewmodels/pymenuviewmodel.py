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
        managers.shared().screensManager().showFriendsViewController_usersListType_(args=[vk.userId(), False])

    def photosTapped(self):
        managers.shared().screensManager().showPhotoAlbumsViewController_push_(args=[vk.userId(), False])

    def answersTapped(self):
        managers.shared().screensManager().showAnswersViewController()

    def groupsTapped(self):
        managers.shared().screensManager().showGroupsViewController_push_(args=[vk.userId(), False])

    def bookmarksTapped(self):
        managers.shared().screensManager().showBookmarksViewController()

    def videosTapped(self):
        managers.shared().screensManager().showVideosViewController_push_(args=[vk.userId(), False])

    def documentsTapped(self):
        managers.shared().screensManager().showDocumentsViewController_(args=[vk.userId()])

    def settingsTapped(self):
        managers.shared().screensManager().showSettingsViewController()
