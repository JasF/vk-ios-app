from objc import managers as Managers
import caches
import services
import viewmodels

try:
    import pymanagers
except Exception as e:
    print(traceback.format_exc())

def launch():
    Managers.shared().screensManager().showAuthorizationViewController()
    pass
