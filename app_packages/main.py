from objc import managers
import services
import screens

def launch():
    managers.shared().screensManager().showAuthorizationViewController()
    pass
