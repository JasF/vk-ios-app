from objc import managers
import vk
from viewmodels.pyfriendsviewmodel import UsersListTypes

def showScreenAfterAuthorization():
    #managers.shared().screensManager().showFriendsViewController_usersListType_push_(args=[vk.userId(), UsersListTypes.FRIENDS, False])
    #managers.shared().screensManager().showChatListViewController()
    #managers.shared().screensManager().showWallViewController()
    #managers.shared().screensManager().showWallViewController_(args=[-41315069]) # Вегетарианская сила
    #managers.shared().screensManager().showWallViewController_(args=[19649085]) # Andrei Vayavoda Second
    #managers.shared().screensManager().showWallViewController_(args=[82108968]) # Aleksandr Kruglov
    managers.shared().screensManager().showPhotoAlbumsViewController_push_(args=[vk.userId(), False])
    #managers.shared().screensManager().showNewsViewController()
    #managers.shared().screensManager().showAnswersViewController()
    #managers.shared().screensManager().showWallViewController_(args=[-166181313]) # Daddy Pasha
    #managers.shared().screensManager().showWallViewController_(args=[-63294313]) # Уроки Медитации [Публичная страница]
    #managers.shared().screensManager().showWallViewController_(args=[-20550925]) # Oum.Ru Здравый Образ Жизни
    #managers.shared().screensManager().showGroupsViewController_push_(args=[vk.userId(), False])
    #managers.shared().screensManager().showBookmarksViewController()
    #managers.shared().screensManager().showVideosViewController_push_(args=[vk.userId(), False])
    #managers.shared().screensManager().showDocumentsViewController_(args=[vk.userId()])
    #managers.shared().screensManager().showSettingsViewController()
    #managers.shared().screensManager().showBlackListViewController()
    pass
