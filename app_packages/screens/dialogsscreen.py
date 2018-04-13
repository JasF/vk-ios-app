from objc import managers

class DialogsHandlerProtocol:
    def menuTapped(self):
        managers.shared().screensManager().showMenu()
