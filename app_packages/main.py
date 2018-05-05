from objc import managers as Managers
import caches
import services
import viewmodels
import traceback

# the c++ extension module

try:
    import pymanagers
    import myextension
    print('myextension hello result is: ' + myextension.hello("hello c++ from python"))
except Exception as e:
    print(traceback.format_exc())

def launch():
    Managers.shared().screensManager().showAuthorizationViewController()
    pass
