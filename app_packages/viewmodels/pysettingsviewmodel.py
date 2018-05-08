from objc import managers
from objcbridge import BridgeBase, ObjCBridgeProtocol
from pymanagers.pydialogsmanager import PyDialogsManager
import settings, analytics

class PySettingsViewModel(ObjCBridgeProtocol):
    def getSettings(self):
        return {'notificationsEnabled': True}
    
    def menuTapped(self):
        managers.shared().screensManager().showMenu()
    
    def notificationsSettingsChanged(self, on):
        print('notificationsSettingsChanged: ' + str(on))
    
    def exitTapped(self):
        dialogsManager = PyDialogsManager()
        index, cancelled = dialogsManager.showRowsDialogWithTitles(['settings_exit'])
        if index == 0 and not cancelled:
            analytics.log('Settings_do_exit')
            settings.set('access_token', '')
            settings.set('user_id', 0)
            settings.write()
            managers.shared().screensManager().showAuthorizationViewController()
        pass
    
    # ObjCBridgeProtocol
    def release(self):
        pass
