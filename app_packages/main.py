from objc import managers as Managers
import caches
import services
import viewmodels
import traceback

# the c++ extension module

try:
    import pymanagers
except Exception as e:
    print(traceback.format_exc())

def launch():
    print('pre showAuthorizationViewController')
    Managers.shared().screensManager().showAuthorizationViewController()
    pass
