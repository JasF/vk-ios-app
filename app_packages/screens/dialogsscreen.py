from objc import managers

class DialogsHandlerProtocol:
    def menuTapped(self):
        managers.shared().screensManager().showMenu()

    def tappedOnDialogWithUserId(self, userId):
        managers.shared().screensManager().showDialogViewController(userId)
