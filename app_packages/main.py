from objc import managers as Managers
import caches
import services
import screens
import viewmodels
try:
    import pymanagers
except Exception as e:
    print('im ex: ' + str(e))

def launch():
    Managers.shared().screensManager().showAuthorizationViewController()
    pass
