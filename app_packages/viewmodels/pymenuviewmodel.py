from objc import managers

class PyMenuViewModel():
    def newsTapped(self):
        managers.shared().screensManager().showWallViewController()
    
    def dialogsTapped(self):
        managers.shared().screensManager().showChatListViewController()

    def friendsTapped(self):
        managers.shared().screensManager().showFriendsViewController()