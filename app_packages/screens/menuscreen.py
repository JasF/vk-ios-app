from objc import managers

class MenuHandlerProtocol:
    def newsTapped(self):
        managers.shared().screensManager().showNewsViewController()
    
    def dialogsTapped(self):
        managers.shared().screensManager().showChatListViewController()
