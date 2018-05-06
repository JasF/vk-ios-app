from objc import managers

def showScreenAfterAuthorization():
        #managers.shared().screensManager().showFriendsViewController_usersListType_(args=[vk.userId(), UsersListTypes.FRIENDS])
        #managers.shared().screensManager().showChatListViewController()
        managers.shared().screensManager().showWallViewController()
        #managers.shared().screensManager().showWallViewController_(args=[19649085]) # Andrei Vayavoda Second
        #managers.shared().screensManager().showWallViewController_(args=[82108968]) # Aleksandr Kruglov
        #managers.shared().screensManager().showPhotoAlbumsViewController_push_(args=[vk.userId(), False])
        #managers.shared().screensManager().showNewsViewController()
        #managers.shared().screensManager().showAnswersViewController()
        #managers.shared().screensManager().showWallViewController_(args=[-63294313]) # Уроки Медитации
        #managers.shared().screensManager().showGroupsViewController_(args=[vk.userId()])
        #managers.shared().screensManager().showBookmarksViewController()
        #managers.shared().screensManager().showVideosViewController_(args=[vk.userId()])
        #managers.shared().screensManager().showDocumentsViewController_(args=[vk.userId()])
        #managers.shared().screensManager().showSettingsViewController()
