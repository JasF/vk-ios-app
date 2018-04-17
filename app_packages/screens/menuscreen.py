from objc import managers

class MenuHandlerProtocol:
    def newsTapped(self):
        managers.shared().screensManager().showWallViewController()
    
    def dialogsTapped(self):
        managers.shared().screensManager().showChatListViewController()
