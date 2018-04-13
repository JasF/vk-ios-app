from objc import managers

class NewsHandlerProtocol:
    def menuTapped(self):
        managers.shared().screensManager().showMenu()

