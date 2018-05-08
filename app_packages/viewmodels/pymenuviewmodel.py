from objc import managers
import vk, analytics
from .pyfriendsviewmodel import UsersListTypes

class PyMenuViewModel():
    def lentaTapped(self):
        analytics.log('Menu_Wall')
        managers.shared().screensManager().showWallViewController()
    
    def newsTapped(self):
        analytics.log('Menu_News')
        managers.shared().screensManager().showNewsViewController()
    
    def dialogsTapped(self):
        analytics.log('Menu_ChatList')
        managers.shared().screensManager().showChatListViewController()

    def friendsTapped(self):
        analytics.log('Menu_Friends')
        managers.shared().screensManager().showFriendsViewController_usersListType_push_(args=[vk.userId(), UsersListTypes.FRIENDS, False])

    def photosTapped(self):
        analytics.log('Menu_Photos')
        managers.shared().screensManager().showPhotoAlbumsViewController_push_(args=[vk.userId(), False])

    def answersTapped(self):
        analytics.log('Menu_Answers')
        managers.shared().screensManager().showAnswersViewController()

    def groupsTapped(self):
        analytics.log('Menu_Groups')
        managers.shared().screensManager().showGroupsViewController_push_(args=[vk.userId(), False])

    def bookmarksTapped(self):
        analytics.log('Menu_Bookmarks')
        managers.shared().screensManager().showBookmarksViewController()

    def videosTapped(self):
        analytics.log('Menu_Videos')
        managers.shared().screensManager().showVideosViewController_push_(args=[vk.userId(), False])

    def documentsTapped(self):
        analytics.log('Menu_Documents')
        managers.shared().screensManager().showDocumentsViewController_(args=[vk.userId()])

    def settingsTapped(self):
        analytics.log('Menu_Settings')
        managers.shared().screensManager().showSettingsViewController()
