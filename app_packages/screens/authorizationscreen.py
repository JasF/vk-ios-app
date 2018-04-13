from objc import managers
import vk

class AuthorizationHandlerProtocol:
    def accessTokenGathered(self, aAccessToken):
        vk.setToken(aAccessToken)
        #managers.shared().screensManager().showDialogsViewController(handler=DialogsHandlerProtocol())
        managers.shared().screensManager().showNewsViewController()
