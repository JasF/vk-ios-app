from objc import managers

class DialogsHandlerProtocol:
    def __init__(self):
        pass
    
    def menuTapped(self):
        managers.shared().screensManager().showMenu()

    def tappedOnDialogWithUserId(self, userId):
        managers.shared().screensManager().showDialogViewController_(args=[userId])
