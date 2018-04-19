from objc import managers
import caches
import services
import screens
import viewmodels

def launch():
    managers.shared().screensManager().showAuthorizationViewController()
    pass
